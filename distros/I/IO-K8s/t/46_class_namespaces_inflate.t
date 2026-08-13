#!/usr/bin/env perl
# karr #18: class_namespaces subclassing must inflate and serialize through
# its parent's k8s attribute registry.
#
# A consumer can register a subclass via class_namespaces:
#
#     IO::K8s->new(class_namespaces => ['My::K8s'])
#
#   package My::K8s::Api::Core::V1::Pod;
#   use parent 'IO::K8s::Api::Core::V1::Pod';
#
# expand_class() then resolves 'Pod' to the subclass, but IO::K8s::Role::
# Resource::_k8s_attr_info did an exact registry lookup, so the subclass saw
# an empty attribute registry: _inflate_struct passed every field through
# raw and the first typed attribute (metadata) collapsed. _k8s_attributes
# read the subclass's own (empty) array, so TO_JSON silently serialized
# nothing. Both lookups now walk @ISA.
#
# Pure local fixtures — no network, no cluster.

use strict;
use warnings;
use Test::More;
use lib 'lib';
use IO::K8s;

# ----------------------------------------------------------------------------
# Test-local classes
# ----------------------------------------------------------------------------
# The Pod subclass is seeded into %INC so IO::K8s::load_class (a bare
# Module::Runtime::require_module) treats it as loaded when inflate runs.

{
    package My::K8s::Api::Core::V1::Pod;
    use parent qw(IO::K8s::Api::Core::V1::Pod);
    $INC{'My/K8s/Api/Core/V1/Pod.pm'} = __FILE__;
}

# Base classes for the nearest-wins / multiple-inheritance scenarios.
# Each gets its own self-bound k8s DSL via use IO::K8s::Resource.
{
    package My::K8s::Test::Base;
    use IO::K8s::Resource;
    k8s active    => 'Bool';
    k8s shared    => 'Str';
    k8s only_base => 'Str';
}

{
    package My::K8s::Test::Sub;
    use IO::K8s::Resource;
    extends 'My::K8s::Test::Base';
    k8s active   => 'Str';    # re-declares inherited attr: nearest wins
    k8s sub_only => 'Str';
}

{
    package My::K8s::Test::MILeft;
    use IO::K8s::Resource;
    k8s left_attr => 'Str';
    k8s dup_attr  => 'Str';
}

{
    package My::K8s::Test::MIRight;
    use IO::K8s::Resource;
    k8s right_attr => 'Str';
    k8s dup_attr   => 'Int';
}

{
    package My::K8s::Test::MIChild;
    use IO::K8s::Resource;
    extends 'My::K8s::Test::MILeft', 'My::K8s::Test::MIRight';
}

{
    package My::K8s::Test::LateReg;
    use IO::K8s::Resource;
    k8s early_attr => 'Str';
}

# ----------------------------------------------------------------------------
# 1. Subclass resolves via class_namespaces and inflates with typed fields
# ----------------------------------------------------------------------------

subtest 'class_namespaces subclass inflates with typed fields' => sub {
    my $io = IO::K8s->new(class_namespaces => ['My::K8s']);

    my $class = $io->expand_class('Pod', 'v1');
    is($class, 'My::K8s::Api::Core::V1::Pod',
        'expand_class("Pod","v1") resolves to the subclass');

    my $fixture = {
        apiVersion => 'v1',
        kind       => 'Pod',
        metadata   => { name => 'my-pod', namespace => 'default', labels => { app => 'web' } },
        spec       => {
            containers => [ { name => 'app', image => 'nginx:1.27' } ],
        },
        status     => { phase => 'Running', hostIP => '10.0.0.5' },
    };

    my $obj = eval { $io->inflate($fixture) };
    ok($obj && ref($obj), 'inflate succeeded') or diag($@);

    SKIP: {
        skip 'inflate failed, cannot assert typed fields', 11 unless $obj && ref($obj);

        isa_ok($obj, 'My::K8s::Api::Core::V1::Pod', 'inflated object is the subclass');
        isa_ok($obj->metadata, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
            'metadata is a typed ObjectMeta, not a raw hashref');
        isa_ok($obj->spec, 'IO::K8s::Api::Core::V1::PodSpec', 'spec is a typed PodSpec');
        isa_ok($obj->status, 'IO::K8s::Api::Core::V1::PodStatus', 'status is a typed PodStatus');
        is($obj->metadata->name, 'my-pod', 'metadata.name survives inflate');
        is($obj->metadata->labels->{app}, 'web', 'metadata.labels survive inflate');
        is($obj->spec->containers->[0]->name, 'app', 'spec.containers[0].name survives inflate');
        is($obj->status->phase, 'Running', 'status.phase survives inflate');
        is($obj->api_version, 'v1', 'api_version derives through inheritance');

        my $json1 = $obj->to_json;
        like($json1, qr/"apiVersion":"v1"/, 'apiVersion emitted');
        like($json1, qr/"kind":"Pod"/, 'kind emitted');

        my $obj2 = $io->inflate($obj->TO_JSON);
        my $json2 = $obj2->to_json;
        is($json2, $json1,
            'inflate -> TO_JSON -> inflate -> TO_JSON is byte-for-byte stable');
    }
};

# ----------------------------------------------------------------------------
# 2. TO_JSON serializes inherited k8s attributes
# ----------------------------------------------------------------------------

subtest 'subclass TO_JSON includes inherited k8s attributes' => sub {
    require IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;
    require IO::K8s::Api::Core::V1::PodSpec;
    require IO::K8s::Api::Core::V1::Container;
    require IO::K8s::Api::Core::V1::PodStatus;

    my $obj = My::K8s::Api::Core::V1::Pod->new(
        metadata => IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => 'p1'),
        spec     => IO::K8s::Api::Core::V1::PodSpec->new(
            containers => [ IO::K8s::Api::Core::V1::Container->new(name => 'app', image => 'nginx') ],
        ),
        status   => IO::K8s::Api::Core::V1::PodStatus->new(phase => 'Running'),
    );

    my $json = $obj->to_json;
    like($json, qr/"spec"/, 'TO_JSON serializes the inherited spec attribute');
    like($json, qr/"status"/, 'TO_JSON serializes the inherited status attribute');
    like($json, qr/"phase":"Running"/, 'nested inherited data is intact');
    like($json, qr/"metadata"/, 'metadata from the APIObject role is intact');
};

# ----------------------------------------------------------------------------
# 3. Nearest wins: a subclass-declared attribute overrides the inherited type
# ----------------------------------------------------------------------------

subtest 'subclass registry override wins; other inherited attrs stay visible' => sub {
    require IO::K8s::Role::Resource;

    my $info = IO::K8s::Role::Resource::_k8s_attr_info('My::K8s::Test::Sub');
    ok($info->{active}{is_str}, 'own active override (is_str) is present');
    ok(!$info->{active}{is_bool}, 'inherited Bool flag is gone for active');
    ok($info->{sub_only}{is_str}, 'own sub_only attr is present');
    ok($info->{shared}{is_str}, 'inherited shared attr stays visible');
    ok($info->{only_base}{is_str}, 'inherited only_base attr stays visible');

    # Serialization-observable: the same value serializes as a JSON boolean
    # on the base class and as a plain number on the overriding subclass.
    my $base = My::K8s::Test::Base->new(active => 1);
    my $sub  = My::K8s::Test::Sub->new(
        active    => 1,
        sub_only  => 'x',
        shared    => 'y',
        only_base => 'z',
    );
    like($base->to_json, qr/"active":true/, 'base serializes active as a JSON boolean');
    like($sub->to_json, qr/"active":1(?:,|\})/, 'sub serializes active via its own Str override');
    like($sub->to_json, qr/"only_base":"z"/, 'inherited only_base still serializes on sub');
};

# ----------------------------------------------------------------------------
# 4. Multiple inheritance: union of attributes, deterministic order, no dup
# ----------------------------------------------------------------------------

subtest 'multiple inheritance merges both parents deterministically' => sub {
    require IO::K8s::Role::Resource;

    my $attrs = IO::K8s::Role::Resource::_k8s_attributes('My::K8s::Test::MIChild');
    is_deeply($attrs, [qw(left_attr dup_attr right_attr)],
        'attributes are the union of both parents, first @ISA parent first, dup_attr deduplicated');

    my $info = IO::K8s::Role::Resource::_k8s_attr_info('My::K8s::Test::MIChild');
    ok($info->{left_attr}{is_str}, 'left_attr visible via inheritance');
    ok($info->{right_attr}{is_str}, 'right_attr visible via inheritance');
    ok($info->{dup_attr}{is_str} && !$info->{dup_attr}{is_int},
        'dup_attr resolves from the first @ISA parent (nearest wins, deterministic)');

    # Moo's constructor only aggregates the first @ISA chain, so a
    # second-parent attribute (right_attr) is not set by ->new — a Moo MI
    # sharp edge, not this module's bug. The accessor itself is inherited
    # and settable, which is what the union lookup must support.
    my $obj = My::K8s::Test::MIChild->new(left_attr => 'L', dup_attr => 'D');
    $obj->right_attr('R');
    my $json = $obj->to_json;
    like($json, qr/"left_attr":"L"/, 'left_attr serialized');
    like($json, qr/"right_attr":"R"/, 'right_attr serialized');
    like($json, qr/"dup_attr":"D"/, 'dup_attr serialized');
    is(scalar(($json =~ /"dup_attr":/g)), 1, 'dup_attr appears exactly once');
};

# ----------------------------------------------------------------------------
# 5. Cache invalidation: a k8s registration after the first lookup is visible
# ----------------------------------------------------------------------------

subtest 'cache invalidated by late k8s registration' => sub {
    my $class = 'My::K8s::Test::LateReg';

    my $info1 = $class->_k8s_attr_info;
    ok(exists $info1->{early_attr}, 'early attr visible in first lookup');
    ok(!exists $info1->{late_attr}, 'late attr not yet registered');

    my $attrs1 = $class->_k8s_attributes;
    is_deeply($attrs1, ['early_attr'], 'first attribute list');

    $class->can('k8s')->(late_attr => 'Str');

    my $info2 = $class->_k8s_attr_info;
    ok(exists $info2->{late_attr}, 'cache invalidated: late attr visible on next lookup');

    my $attrs2 = $class->_k8s_attributes;
    is_deeply($attrs2, ['early_attr', 'late_attr'], 'attribute list refreshed after invalidation');
};

done_testing;
