#!/usr/bin/env perl
# D3: IO::K8s::AutoGen carries an OpenAPI property's required/enum/minimum/
# maximum/pattern/default/description/nullable/x-kubernetes-preserve-
# unknown-fields into the generated class's field options.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s::AutoGen;

IO::K8s::AutoGen::clear_cache();

require JSON::PP;

# 'spec' is a $ref to a sibling definition, not inlined. Since step 3 (D10,
# k94) an inline `type: object` with its own `properties` is ALSO a typed
# nested class, not an opaque hash-of-strings -- this fixture keeps the
# $ref shape anyway because that is what a real swagger v2 host actually
# produces for a nested type, and is what _schema_to_type_spec's existing
# $ref path already turns into a typed nested class via get_or_generate --
# exactly the class this test needs to inspect.
my $spec_def = {
    type => 'object',
    required => [ 'mode' ],
    properties => {
        mode     => { type => 'string', enum => [ 'fast', 'safe' ], description => 'operating mode', default => 'safe' },
        replicas => { type => 'integer', minimum => 0, maximum => 5, default => 1 },
        ratio    => { type => 'number', minimum => 0.1 },
        name     => { type => 'string', pattern => '^[a-z]+$' },
        tags     => { type => 'array', items => { type => 'string', enum => [ 'a', 'b' ] } },
        ports    => { type => 'array', items => { type => 'integer', maximum => 65535 } },
        weird    => { type => 'string', pattern => '[' },
        flag     => { type => 'boolean', default => JSON::PP::true() },
        extra    => { type => 'object', 'x-kubernetes-preserve-unknown-fields' => JSON::PP::true(), nullable => JSON::PP::true() },
        note     => { type => 'string', nullable => JSON::PP::true(), default => undef },
        flagged  => { type => 'string', nullable => 'false' },
        # Important 2 of the k93 review: a malformed range or an
        # out-of-bounds default must not kill class generation.
        swapped_range => { type => 'integer', minimum => 10, maximum => 1 },
        bad_min       => { type => 'integer', minimum => 'low' },
        bad_default   => { type => 'integer', default => 'x' },
        enum_default  => { type => 'string', enum => [ 'a', 'b' ], default => 'nope' },
    },
};

# Critical 1 of the k93 review: a status schema's own required list must
# be recorded (for to_crd) but not enforced -- a real cluster can return an
# empty status right after creation, before its controller has populated
# any required condition.
my $status_def = {
    type => 'object',
    required => [ 'conditions' ],
    properties => {
        conditions => { type => 'array', items => { type => 'object' } },
    },
};

my $schema = {
    type => 'object',
    'x-kubernetes-group-version-kind' => [ { group => 'opts.example.com', version => 'v1', kind => 'Knob' } ],
    required => [ 'spec' ],
    properties => {
        apiVersion => { type => 'string' },
        kind       => { type => 'string' },
        metadata   => { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta' },
        spec       => { '$ref' => '#/definitions/com.example.opts.v1.KnobSpec' },
        status     => { '$ref' => '#/definitions/com.example.opts.v1.KnobStatus' },
    },
};

my $all_defs = {
    'com.example.opts.v1.KnobSpec'   => $spec_def,
    'com.example.opts.v1.KnobStatus' => $status_def,
};

my $class;
lives_ok {
    $class = IO::K8s::AutoGen::get_or_generate('com.example.opts.v1.Knob', $schema, $all_defs, 'IO::K8s::_AUTOGEN_opts',
        api_version => 'opts.example.com/v1', kind => 'Knob', resource_plural => 'knobs', is_namespaced => 1);
} 'class generation lives with a null default (nullable field), mixed nullable spellings, and malformed range/default options';
my $spec_class = $class->_k8s_attr_info->{spec}{class};
my $status_class = $class->_k8s_attr_info->{status}{class};

subtest 'registry of the generated spec class' => sub {
    my $info = $spec_class->_k8s_attr_info;
    is($info->{mode}{required}, 1, 'required list -> required');
    is_deeply($info->{mode}{options}{enum}, [ 'fast', 'safe' ], 'enum');
    is($info->{mode}{options}{description}, 'operating mode', 'description');
    is($info->{mode}{options}{default}, 'safe', 'default');
    is($info->{replicas}{options}{minimum}, 0, 'minimum');
    is($info->{replicas}{options}{maximum}, 5, 'maximum');
    is($info->{ratio}{options}{minimum}, 0.1, 'Num minimum');
    is(ref $info->{name}{options}{pattern}, 'Regexp', 'pattern compiled');
    is_deeply($info->{tags}{options}{enum}, [ 'a', 'b' ], 'array items enum lifted to the field');
    is($info->{ports}{options}{maximum}, 65535, 'array items maximum lifted');
    ok(!exists $info->{weird}{options}{pattern}, 'an uncompilable pattern is dropped, the class still exists');
    ok($info->{flag}{options}{default}, 'boolean default kept');
    ok(!exists $info->{flag}{options}{enum}, 'no value constraints on Bool');
    is($info->{extra}{options}{preserve_unknown}, 1, 'x-kubernetes-preserve-unknown-fields');
    is($info->{extra}{options}{nullable}, 1, 'nullable');
    is($info->{note}{options}{nullable}, 1, 'note: nullable normalized from a JSON::PP::Boolean');
    ok(!exists $info->{note}{options}{default}, 'note: a null default is no default at all');
    ok(!exists $info->{flagged}{options}{nullable}, "flagged: the string 'false' is false, not truthy Perl");
    is($class->_k8s_attr_info->{spec}{required}, 1, 'top-level required list applies too');

    # Important 2: a malformed range or an out-of-bounds default is
    # dropped, not fatal, and the class still generated (see the lives_ok
    # above).
    ok(!exists $info->{swapped_range}{options}{minimum}, 'minimum > maximum: minimum dropped');
    ok(!exists $info->{swapped_range}{options}{maximum}, 'minimum > maximum: maximum dropped too');
    ok(!exists $info->{bad_min}{options}{minimum}, 'non-numeric minimum dropped');
    ok(!exists $info->{bad_default}{options}{default}, "default outside the field's own type dropped");
    is_deeply($info->{enum_default}{options}{enum}, [ 'a', 'b' ], 'enum itself kept even though its default was dropped');
    ok(!exists $info->{enum_default}{options}{default}, 'default outside the enum dropped');
};

subtest 'constraints are enforced on the generated class' => sub {
    lives_ok { $spec_class->new(mode => 'fast', replicas => 5, name => 'abc', tags => ['a'], ports => [80]) } 'valid values';
    throws_ok { $spec_class->new(mode => 'slow') } qr/Value "slow" is not one of: fast, safe/, 'enum';
    throws_ok { $spec_class->new(mode => 'fast', replicas => 6) } qr/above the maximum 5/, 'maximum';
    throws_ok { $spec_class->new(mode => 'fast', name => 'ABC') } qr/does not match the pattern/, 'pattern';
    throws_ok { $spec_class->new(mode => 'fast', tags => ['c']) } qr/is not one of: a, b/, 'array element enum';
    throws_ok { $spec_class->new(mode => 'fast', ports => [70000]) } qr/above the maximum 65535/, 'array element maximum';
    # Critical 1 of the k93 review: the schema's required list is recorded
    # (asserted above: $info->{mode}{required} == 1) but not enforced --
    # AutoGen passes required => 'schema', so a generated class stays
    # constructible without it, the way inflate needs it to for a real
    # cluster document that omits a schema-required field.
    lives_ok { $spec_class->new() } "required => 'schema' does not enforce at construction";
    lives_ok { $spec_class->new(mode => 'fast', weird => 'anything[') } 'dropped pattern enforces nothing';
};

subtest "a status schema's own required list is recorded, not enforced (Critical 1 regression)" => sub {
    is($status_class->_k8s_attr_info->{conditions}{required}, 1, "status's own required list -> required recorded");
    lives_ok { $status_class->new() } 'status object constructs without its schema-required field';
};

subtest 'inflate through IO::K8s honours the same constraints' => sub {
    require IO::K8s;
    my $k8s = IO::K8s->new(openapi_spec => { definitions => { %$all_defs, 'com.example.opts.v1.Knob' => $schema } });
    throws_ok {
        $k8s->inflate({ apiVersion => 'opts.example.com/v1', kind => 'Knob', metadata => { name => 'k' }, spec => { mode => 'slow' } });
    } qr/is not one of: fast, safe/, 'a document from the cluster with a bad enum value fails at inflate';

    # Critical 1 regression: a real cluster document whose status is still
    # empty (right after creation, before a controller populates
    # `conditions`) must inflate, even though the status schema lists
    # `conditions` as required.
    lives_ok {
        $k8s->inflate({
            apiVersion => 'opts.example.com/v1', kind => 'Knob',
            metadata => { name => 'x' }, spec => { mode => 'fast' }, status => {},
        });
    } "an empty status inflates despite the status schema's own required list";
};

subtest 'an enum containing a JSON null is dropped, without warning (Minor 7)' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $null_spec_def = {
        type => 'object',
        properties => {
            choice => { type => 'string', enum => [ 'a', undef ] },
        },
    };
    my $null_schema = {
        type => 'object',
        'x-kubernetes-group-version-kind' => [ { group => 'opts.example.com', version => 'v1', kind => 'NullEnum' } ],
        properties => {
            apiVersion => { type => 'string' },
            kind       => { type => 'string' },
            metadata   => { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta' },
            spec       => { '$ref' => '#/definitions/com.example.opts.v1.NullEnumSpec' },
        },
    };
    my $null_defs = { 'com.example.opts.v1.NullEnumSpec' => $null_spec_def };

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $null_class;
    lives_ok {
        $null_class = IO::K8s::AutoGen::get_or_generate('com.example.opts.v1.NullEnum', $null_schema, $null_defs, 'IO::K8s::_AUTOGEN_opts',
            api_version => 'opts.example.com/v1', kind => 'NullEnum', resource_plural => 'nullenums', is_namespaced => 1);
    } 'class generation lives with a null element in an enum';
    is_deeply(\@warnings, [], 'no "Use of uninitialized value" warning');

    my $null_spec_class = $null_class->_k8s_attr_info->{spec}{class};
    ok(!exists $null_spec_class->_k8s_attr_info->{choice}{options}{enum}, 'the enum itself is dropped, not recorded');
};

done_testing;
