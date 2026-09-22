#!/usr/bin/env perl
# D10: an inline `type: object` with properties becomes a nested class named
# after its place in the parent; array items and map values shaped that way
# too. Property-less objects and additionalProperties-only maps stay opaque
# (k55). Hash-style access on the result keeps working (blessed hash).
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s::AutoGen;
use IO::K8s;

IO::K8s::AutoGen::clear_cache();

my $schema = {
    type => 'object',
    'x-kubernetes-group-version-kind' => [ { group => 'nest.example.com', version => 'v1', kind => 'Widget' } ],
    properties => {
        apiVersion => { type => 'string' },
        kind       => { type => 'string' },
        metadata   => { type => 'object' },
        spec => {
            type => 'object',
            required => [ 'name' ],
            properties => {
                name  => { type => 'string' },
                limit => {
                    type => 'object',
                    properties => {
                        average => { type => 'integer', minimum => 0 },
                        burst   => { type => 'integer' },
                    },
                },
                routes => {
                    type  => 'array',
                    items => {
                        type => 'object',
                        properties => {
                            match    => { type => 'string' },
                            priority => { type => 'integer' },
                        },
                    },
                },
                weights => {
                    type => 'object',
                    additionalProperties => {
                        type => 'object',
                        properties => { value => { type => 'integer' } },
                    },
                },
                labels  => { type => 'object', additionalProperties => { type => 'string' } },
                blob    => { type => 'object' },
                'x-extra' => { type => 'object', properties => { on => { type => 'boolean' } } },
            },
        },
    },
};

my $ns = 'IO::K8s::_AUTOGEN_nested';
my $class = IO::K8s::AutoGen::get_or_generate('com.example.nest.v1.Widget', $schema, {}, $ns,
    api_version => 'nest.example.com/v1', kind => 'Widget', resource_plural => 'widgets', is_namespaced => 1);

subtest 'nested classes exist with path-derived names' => sub {
    my $spec = $class->_k8s_attr_info->{spec};
    ok($spec->{is_object}, 'spec is an object field');
    is($spec->{class}, "$class\::Spec", 'spec class named <Kind>::Spec');
    my $sinfo = $spec->{class}->_k8s_attr_info;
    is($sinfo->{limit}{class}, "$class\::Spec::Limit", 'object property -> <Parent>::<Prop>');
    ok($sinfo->{routes}{is_array_of_objects}, 'array of objects');
    is($sinfo->{routes}{class}, "$class\::Spec::RoutesItem", 'array items -> <Parent>::<Prop>Item');
    ok($sinfo->{weights}{is_hash_of_objects}, 'map of objects');
    is($sinfo->{weights}{class}, "$class\::Spec::WeightsValue", 'map values -> <Parent>::<Prop>Value');
    ok($sinfo->{labels}{is_hash_of_str}, 'additionalProperties: string stays an opaque map (k55)');
    ok($sinfo->{blob}{is_hash_of_str}, 'property-less object stays opaque');
    is($sinfo->{x_extra}{class}, "$class\::Spec::X_extra", 'sanitized key names the nested class');
    is($sinfo->{name}{required}, 1, 'required list applies inside the nested class');
    is($sinfo->{limit}{class}->_k8s_attr_info->{average}{options}{minimum}, 0, 'options apply below the top level');
};

subtest 'inflate builds the nested objects and round-trips' => sub {
    require JSON::PP;
    my $k8s = IO::K8s->new;
    $k8s->add({ Widget => "+$class" });
    my $doc = {
        apiVersion => 'nest.example.com/v1', kind => 'Widget',
        metadata   => { name => 'w' },
        spec => {
            name    => 'n',
            limit   => { average => 10, burst => 20 },
            routes  => [ { match => 'a', priority => 1 }, { match => 'b' } ],
            weights => { x => { value => 5 } },
            labels  => { app => 'web' },
            blob    => { anything => [ 1, 2 ] },
            'x-extra' => { on => JSON::PP::true() },
        },
    };
    my $obj = $k8s->inflate($doc);
    isa_ok($obj->spec, "$class\::Spec");
    isa_ok($obj->spec->limit, "$class\::Spec::Limit");
    isa_ok($obj->spec->routes->[1], "$class\::Spec::RoutesItem");
    isa_ok($obj->spec->weights->{x}, "$class\::Spec::WeightsValue");
    is($obj->spec->{name}, 'n', 'hash-style access on the blessed hash still works');
    my $out = $obj->TO_JSON;
    is_deeply($out->{spec}{limit}, { average => 10, burst => 20 }, 'nested object round-trips');
    is_deeply($out->{spec}{routes}[0], { match => 'a', priority => 1 }, 'array item round-trips');
    is_deeply($out->{spec}{weights}, { x => { value => 5 } }, 'map value round-trips');
    is_deeply($out->{spec}{blob}, { anything => [ 1, 2 ] }, 'opaque object round-trips');
    ok($out->{spec}{'x-extra'}{on}, 'sanitized nested key round-trips under its JSON name');
    throws_ok { $k8s->inflate({ %$doc, spec => { name => 'n', limit => { average => -1 } } }) } qr/below the minimum 0/,
        'constraints are enforced inside nested classes';
    my $k8s_strict = IO::K8s->new(strict => 1);
    $k8s_strict->add({ Widget => "+$class" });
    throws_ok { $k8s_strict->inflate({ %$doc, spec => { name => 'n', limit => { typo => 1 } } }) }
        qr/Unknown field 'typo' for \Q$class\E::Spec::Limit/, 'strict reaches nested classes';
};

subtest 'nested classes are cached per parent, not regenerated' => sub {
    my $again = IO::K8s::AutoGen::get_or_generate('com.example.nest.v1.Widget', $schema, {}, $ns,
        api_version => 'nest.example.com/v1', kind => 'Widget', resource_plural => 'widgets', is_namespaced => 1);
    is($again, $class, 'same Kind class');
    my @nested = sort grep { /^\Q$class\E::/ } IO::K8s::AutoGen::generated_classes();
    my @expected = sort
        "$class\::Spec",
        "$class\::Spec::Limit",
        "$class\::Spec::RoutesItem",
        "$class\::Spec::WeightsValue",
        "$class\::Spec::X_extra";
    is_deeply(\@nested, \@expected, 'exactly the five expected nested classes exist');
};

# Carried over from the step-2 final re-review: _field_options normalized a
# Bool default with _normalize_bool for every Bool kind, including [Bool],
# where the default is itself an arrayref -- _normalize_bool only accepts a
# scalar or scalar ref and dies on a bare ARRAY ref, which used to kill class
# generation over a malformed-looking but perfectly legal array default.
subtest 'array-of-Bool default is normalized per element, not left to die on the arrayref' => sub {
    require JSON::PP;
    IO::K8s::AutoGen::clear_cache();
    my $schema = {
        type => 'object',
        properties => {
            flags => {
                type    => 'array',
                items   => { type => 'boolean' },
                default => [ JSON::PP::true(), JSON::PP::false() ],
            },
            # A malformed element (an arrayref, not anything _normalize_bool
            # can mean true/false for) must drop the whole default rather
            # than kill class generation -- the same "malformed default is
            # dropped" rule every other option in _field_options follows.
            flags2 => {
                type    => 'array',
                items   => { type => 'boolean' },
                default => [ JSON::PP::true(), [1] ],
            },
        },
    };
    my $flag_class;
    lives_ok {
        $flag_class = IO::K8s::AutoGen::get_or_generate(
            'test.example.v1.Flaggy72', $schema, {}, 'IO::K8s::_AUTOGEN_karr72flags',
        );
    } 'a [Bool] default does not kill class generation';
    my $info = $flag_class->_k8s_attr_info;
    is_deeply($info->{flags}{options}{default}, [ 1, 0 ],
        'the recorded default is normalized to plain 0/1 per element');
    ok(!exists $info->{flags2}{options}{default},
        'a default with a non-boolean element is dropped entirely, not partially normalized');
};

# k56 line, reached from a name collision instead of an unresolved $ref: two
# schema keys that sanitize + ucfirst to the same class segment must not
# silently share a class -- `routes` (array of objects, gets an `Item`
# suffix) and a sibling plain-object field `routesItem` both want
# `...::RoutesItem`. Generating the class anyway would type the second field
# as the first field's class and drop it on every inflate/TO_JSON round-trip
# in the default non-strict mode -- exactly the failure _croak_unresolved_ref
# exists to prevent. Uses its own def name / namespace: _generate_class marks
# the parent class generated before the property loop runs, so a croak
# partway through leaves a half-built parent cached under that name, which
# must not collide with any other subtest's class.
subtest 'k94 collision: two schema keys collapsing to the same nested class name croak (fail closed)' => sub {
    IO::K8s::AutoGen::clear_cache();
    my $collide_schema = {
        type => 'object',
        properties => {
            spec => {
                type => 'object',
                properties => {
                    routes => {
                        type  => 'array',
                        items => {
                            type       => 'object',
                            properties => { match => { type => 'string' } },
                        },
                    },
                    routesItem => {
                        type       => 'object',
                        properties => { totallyDifferent => { type => 'integer' } },
                    },
                },
            },
        },
    };
    throws_ok {
        IO::K8s::AutoGen::get_or_generate(
            'test.example.v1.Collider72', $collide_schema, {}, 'IO::K8s::_AUTOGEN_karr72collide',
        );
    } qr/class name .*::RoutesItem is already taken by field 'routes'/,
        'a name collision between two schema keys croaks instead of silently reusing the first field\'s class';
};

# cert-manager's CRDs inline a full PodTemplateSpec several levels into a
# Challenge/ClusterIssuer 'spec'; the path-derived name for the deepest
# levels ran past Perl's 251-character limit on a fully qualified
# identifier and killed class generation ("Identifier too long"). Two
# sibling branches with an otherwise identical eight-level shape, differing
# only in their first segment, exercise both the shortening itself and that
# it does not collapse two different long paths into one class.
subtest 'a path-derived name past 200 chars is shortened to <root>::_<10 hex chars>' => sub {
    IO::K8s::AutoGen::clear_cache();

    my @keys = map {
        my $base = "level$_";
        $base . ('x' x (30 - length($base)));
    } 1 .. 8;
    is(length($_), 30, "fixture key is 30 chars: $_") for @keys;

    my $leaf = { type => 'object', properties => { value => { type => 'string' } } };
    my $eight_deep = $leaf;
    $eight_deep = { type => 'object', properties => { $_ => $eight_deep } } for reverse @keys;

    my $schema = {
        type => 'object',
        'x-kubernetes-group-version-kind' => [ { group => 'deep.example.com', version => 'v1', kind => 'Deep' } ],
        properties => {
            apiVersion => { type => 'string' },
            kind       => { type => 'string' },
            metadata   => { type => 'object' },
            spec => {
                type => 'object',
                properties => {
                    brancha => $eight_deep,
                    branchb => $eight_deep,
                },
            },
        },
    };

    my $class;
    lives_ok {
        $class = IO::K8s::AutoGen::get_or_generate('com.example.deep.v1.Deep', $schema, {}, 'IO::K8s::_AUTOGEN_karr_deepnames',
            api_version => 'deep.example.com/v1', kind => 'Deep', resource_plural => 'deeps', is_namespaced => 1);
    } 'generation lives instead of dying "Identifier too long"';

    my $spec_class = $class->_k8s_attr_info->{spec}{class};
    my ($a_class, $b_class) = ($spec_class->_k8s_attr_info->{brancha}{class}, $spec_class->_k8s_attr_info->{branchb}{class});
    for my $key (@keys) {
        $a_class = $a_class->_k8s_attr_info->{$key}{class};
        $b_class = $b_class->_k8s_attr_info->{$key}{class};
    }

    like($a_class, qr/::_[0-9a-f]{10}$/, 'the deepest class name is the shortened <root>::_<hash> form');
    like($b_class, qr/::_[0-9a-f]{10}$/, "so is the sibling branch's");
    isnt($a_class, $b_class, 'two structurally-identical deep paths under different branches do not collide');
    is(substr($a_class, 0, length($class) + 2), "$class\::", 'the shortened name still sits under the root');

    is(IO::K8s::AutoGen::class_root($a_class), $class, 'class_root recovers the Kind class from the deepest class');
    is(IO::K8s::AutoGen::class_root($class), $class, 'a root is its own class_root');
    ok(!defined(IO::K8s::AutoGen::class_path($class)), 'a root has no class_path');

    my $path = IO::K8s::AutoGen::class_path($a_class);
    like($path, qr/^Spec::Brancha::/, 'class_path is the true, unshortened logical path, never the hash');
    like($path, qr/\Q@{[ ucfirst($keys[-1]) ]}\E$/, 'ending at the deepest key (sanitized + ucfirst)');
    isnt($path, IO::K8s::AutoGen::class_path($b_class), "the two branches' logical paths differ too");
    ok(length("$class\::$path") > 200, 'the logical name really is past the shortening threshold');

    # A document with a value at the deepest level round-trips.
    my $leaf_doc = { value => 'leaf-value' };
    my $branch_doc = $leaf_doc;
    $branch_doc = { $_ => $branch_doc } for reverse @keys;
    my $k8s = IO::K8s->new;
    $k8s->add({ Deep => "+$class" });
    my $doc = {
        apiVersion => 'deep.example.com/v1', kind => 'Deep',
        metadata   => { name => 'd' },
        spec       => { brancha => $branch_doc },
    };
    my $obj = $k8s->inflate($doc);
    my $walked = $obj->spec->brancha;
    $walked = $walked->{$_} for @keys;
    isa_ok($walked, $a_class, 'inflate builds the shortened nested class all the way down');
    is($walked->{value}, 'leaf-value', 'the deepest value is reachable through hash-style access');
    is_deeply($obj->TO_JSON->{spec}, { brancha => $branch_doc }, 'the deep document round-trips through TO_JSON');
};

done_testing;
