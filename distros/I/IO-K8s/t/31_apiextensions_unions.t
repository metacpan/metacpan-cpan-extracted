#!/usr/bin/env perl
# Regression coverage for karr ticket #1: four apiextensions.k8s.io/v1 union
# classes that JSONSchemaProps depends on but that the distribution didn't
# ship (JSON, JSONSchemaPropsOrArray, JSONSchemaPropsOrBool,
# JSONSchemaPropsOrStringArray). Without them, inflating any real
# CustomResourceDefinition that uses `items`, `additionalProperties`,
# `dependencies`, or a JSON `default`/`example`/`enum` value died with
# "Can't locate .../JSON.pm in @INC" (or the *OrArray/*OrBool/*OrStringArray
# equivalent).
#
# All four are Kubernetes union types: upstream they serialize as the bare
# alternative, never as a tagged wrapper. So the thing actually under test
# throughout this file is TO_JSON/to_json/to_yaml output, not just accessors
# on the inflated object — that's the failure mode that reaches Kubernetes.

use strict;
use warnings;
use Test::More;
use YAML::PP;
use JSON::MaybeXS;

use IO::K8s;

my $k8s = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1, allow_nonref => 1);

sub json_scalar {
    my ($value) = @_;
    return $json->encode($value);
}

my $CRD        = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition';
my $PROPS      = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps';
my $OR_ARRAY   = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrArray';
my $OR_BOOL    = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool';
my $OR_STRARR  = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrStringArray';
my $JSON_VAL   = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON';

# Wrap a JSONSchemaProps fragment (for the `spec` property of the CRD's
# openAPIV3Schema) in a minimal but complete CustomResourceDefinition struct.
sub minimal_crd {
    my (%spec_schema) = @_;
    return {
        apiVersion => 'apiextensions.k8s.io/v1',
        kind       => 'CustomResourceDefinition',
        metadata   => { name => 'widgets.example.com' },
        spec       => {
            group => 'example.com',
            scope => 'Namespaced',
            names => { plural => 'widgets', kind => 'Widget' },
            versions => [{
                name    => 'v1',
                served  => \1,
                storage => \1,
                schema  => { openAPIV3Schema => {
                    type       => 'object',
                    properties => { spec => { type => 'object', %spec_schema } },
                } },
            }],
        },
    };
}

# A JSONSchemaProps fragment for `spec` that exercises all four union
# classes at once: JSONSchemaPropsOrArray (single + tuple items),
# JSONSchemaPropsOrBool (schema/true/false), JSONSchemaPropsOrStringArray
# (string-array + schema dependencies) and JSON (default/example/enum with
# mixed value types, including a JSON boolean and a null).
sub combined_spec_schema {
    return (
        properties => {
            tags => {
                type  => 'array',
                items => { type => 'string' },
            },
            matrix => {
                type  => 'array',
                items => [ { type => 'string' }, { type => 'integer' } ],
            },
            config => {
                type                 => 'object',
                additionalProperties => { type => 'string' },
            },
            locked => {
                type                 => 'object',
                additionalProperties => JSON::MaybeXS::false,
            },
            open => {
                type                 => 'object',
                additionalProperties => JSON::MaybeXS::true,
            },
            mode => {
                type    => 'string',
                default => 'auto',
                example => 'manual',
                enum    => [ 'auto', 'manual', 3, JSON::MaybeXS::true, JSON::MaybeXS::false, { a => 1 }, [ 1, 2 ], undef ],
            },
        },
        dependencies => {
            billingAddress => ['creditCard'],
            shipping       => { type => 'object' },
        },
    );
}

sub inflate_props {
    my ($struct) = @_;
    return $k8s->struct_to_object($PROPS, $struct);
}

# ============================================================================
# 1. The ticket's exact repro: a minimal CRD with one `type: array` property.
#    Before the fix this died with "Can't locate .../JSONSchemaPropsOrArray.pm".
# ============================================================================

subtest 'ticket repro: minimal CRD with an array property inflates and round-trips' => sub {
    my $crd = minimal_crd(properties => {
        tags => { type => 'array', items => { type => 'string' } },
    });

    # struct_to_object with the fully-qualified class name, exactly as in the
    # ticket's repro snippet.
    my $obj = $k8s->struct_to_object($CRD, $crd);
    isa_ok($obj, $CRD);

    my $items = $obj->spec->versions->[0]->schema->openAPIV3Schema
        ->properties->{spec}->properties->{tags}->items;
    isa_ok($items, $OR_ARRAY);
    ok($items->is_schema, 'single-schema arm in use');
    isa_ok($items->schema, $PROPS);
    is($items->schema->type, 'string', 'wrapped schema type preserved');

    my $got = $obj->TO_JSON;
    is_deeply(
        $got->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties}{spec}{properties}{tags}{items},
        { type => 'string' },
        'items serializes bare, not wrapped as {schema=>{...}}',
    );

    # Same repro via inflate()/kind — the path a real manifest consumer hits.
    my $obj2 = $k8s->inflate($crd);
    isa_ok($obj2, $CRD);
    is_deeply($obj2->TO_JSON, $got, 'inflate() and struct_to_object() agree');
};

# ============================================================================
# 2. One case per arm, both directions (inflate a struct, then serialize the
#    resulting object back and check the bare arm comes out again).
# ============================================================================

subtest 'items: single-schema arm' => sub {
    my $obj = inflate_props({ type => 'array', items => { type => 'string' } });

    ok($obj->items->is_schema, 'is_schema true');
    is($obj->items->schema->type, 'string', 'schema arm populated');
    is($obj->items->schemas, undef, 'schemas arm left unset');

    is_deeply($obj->TO_JSON->{items}, { type => 'string' }, 'serializes bare schema, not an array');
};

subtest 'items: array-of-schemas arm (tuple items)' => sub {
    my $obj = inflate_props({
        type  => 'array',
        items => [ { type => 'string' }, { type => 'integer' } ],
    });

    ok(!$obj->items->is_schema, 'is_schema false');
    is(scalar @{ $obj->items->schemas }, 2, 'two schemas in the tuple');
    is($obj->items->schemas->[0]->type, 'string', 'first tuple schema');
    is($obj->items->schemas->[1]->type, 'integer', 'second tuple schema');
    is($obj->items->schema, undef, 'schema arm left unset');

    is_deeply(
        $obj->TO_JSON->{items},
        [ { type => 'string' }, { type => 'integer' } ],
        'serializes bare array of schemas',
    );
};

subtest 'additionalProperties: schema arm' => sub {
    my $obj = inflate_props({ type => 'object', additionalProperties => { type => 'string' } });

    ok($obj->additionalProperties->is_schema, 'is_schema true');
    is($obj->additionalProperties->schema->type, 'string', 'schema arm populated');

    is_deeply($obj->TO_JSON->{additionalProperties}, { type => 'string' }, 'serializes bare schema');
};

subtest 'additionalProperties: false' => sub {
    my $obj = inflate_props({ type => 'object', additionalProperties => JSON::MaybeXS::false });

    ok(!$obj->additionalProperties->is_schema, 'is_schema false');
    is($obj->additionalProperties->allows, 0, 'allows is false');

    is(json_scalar($obj->TO_JSON->{additionalProperties}), 'false', 'serializes as the JSON literal false');
};

subtest 'additionalProperties: true' => sub {
    my $obj = inflate_props({ type => 'object', additionalProperties => JSON::MaybeXS::true });

    ok(!$obj->additionalProperties->is_schema, 'is_schema false');
    is($obj->additionalProperties->allows, 1, 'allows is true');

    is(json_scalar($obj->TO_JSON->{additionalProperties}), 'true', 'serializes as the JSON literal true');
};

subtest 'dependencies: string-array arm' => sub {
    my $obj = inflate_props({
        type         => 'object',
        dependencies => { creditCard => ['billingAddress'] },
    });

    my $dep = $obj->dependencies->{creditCard};
    isa_ok($dep, $OR_STRARR);
    ok(!$dep->is_schema, 'is_schema false');
    is_deeply($dep->property, ['billingAddress'], 'property arm populated');

    is_deeply($obj->TO_JSON->{dependencies}{creditCard}, ['billingAddress'], 'serializes bare string array');
};

subtest 'dependencies: schema arm' => sub {
    my $obj = inflate_props({
        type         => 'object',
        dependencies => { shipping => { type => 'object' } },
    });

    my $dep = $obj->dependencies->{shipping};
    ok($dep->is_schema, 'is_schema true');
    is($dep->schema->type, 'object', 'schema arm populated');

    is_deeply($obj->TO_JSON->{dependencies}{shipping}, { type => 'object' }, 'serializes bare schema');
};

subtest 'JSON: string, number, bool, hash, array and null' => sub {
    my $obj = inflate_props({
        type    => 'string',
        default => 'nginx',
        example => 42,
        enum    => [ 'auto', 3, JSON::MaybeXS::true, JSON::MaybeXS::false, { a => 1 }, [ 1, 2 ], undef ],
    });

    isa_ok($obj->default, $JSON_VAL);
    is($obj->default->value, 'nginx', 'default: string value carried through');
    isa_ok($obj->example, $JSON_VAL);
    is($obj->example->value, 42, 'example: number value carried through');

    my $enum = $obj->enum;
    is(scalar @$enum, 7, 'enum has all 7 entries');
    isa_ok($enum->[$_], $JSON_VAL) for 0 .. 6;

    my $out = $obj->TO_JSON;
    is($out->{default}, 'nginx', 'default serializes as a bare string');
    is($out->{example}, 42, 'example serializes as a bare number');

    my $out_enum = $out->{enum};
    is($out_enum->[0], 'auto', 'enum[0]: string');
    is($out_enum->[1], 3, 'enum[1]: number');
    ok($out_enum->[2], 'enum[2]: bool true is truthy');
    is(json_scalar($out_enum->[2]), 'true', 'enum[2]: encodes as JSON true');
    ok(!$out_enum->[3], 'enum[3]: bool false is falsy');
    is(json_scalar($out_enum->[3]), 'false', 'enum[3]: encodes as JSON false');
    is_deeply($out_enum->[4], { a => 1 }, 'enum[4]: hash');
    is_deeply($out_enum->[5], [ 1, 2 ], 'enum[5]: array');
    is($out_enum->[6], undef, 'enum[6]: null stays undef, not dropped or stringified');
};

# ============================================================================
# 3. Empty array arms must stay arrays and must not fall back to the schema
#    arm just because the array happens to be empty.
# ============================================================================

subtest 'empty array arms stay arrays, not the schema arm' => sub {
    my $obj = inflate_props({
        type         => 'object',
        items        => [],
        dependencies => { a => [] },
    });

    ok(!$obj->items->is_schema, 'empty items tuple is still the array arm');
    is_deeply($obj->items->schemas, [], 'schemas is an empty arrayref, not undef');
    is($obj->items->schema, undef, 'schema arm stays unset');
    is_deeply($obj->TO_JSON->{items}, [], 'items serializes as []');

    my $dep = $obj->dependencies->{a};
    ok(!$dep->is_schema, 'empty dependency list is still the property arm');
    is_deeply($dep->property, [], 'property is an empty arrayref, not undef');
    is_deeply($obj->TO_JSON->{dependencies}{a}, [], 'dependency serializes as []');
};

# ============================================================================
# 4. All three boolean input encodings land on `allows`. \0 is the sharp
#    edge: it is a reference, and references are always true in Perl boolean
#    context, so a naive `$struct ? 1 : 0` on the ref itself would get this
#    backwards. FROM_STRUCT must dereference before boolifying.
# ============================================================================

subtest 'additionalProperties boolean arm accepts all three input encodings' => sub {
    # JSON::PP::Boolean, as produced by JSON::MaybeXS decode and as a caller
    # might pass directly.
    is(inflate_props({ type => 'object', additionalProperties => JSON::MaybeXS::true })
        ->additionalProperties->allows, 1, 'JSON::PP::Boolean true -> allows=1');
    is(inflate_props({ type => 'object', additionalProperties => JSON::MaybeXS::false })
        ->additionalProperties->allows, 0, 'JSON::PP::Boolean false -> allows=0');

    # \1 / \0 scalar refs, as used by this distribution's own CRD fixtures
    # (e.g. `served => \1` in the ticket repro).
    is(inflate_props({ type => 'object', additionalProperties => \1 })
        ->additionalProperties->allows, 1, '\\1 -> allows=1');
    is(inflate_props({ type => 'object', additionalProperties => \0 })
        ->additionalProperties->allows, 0, '\\0 -> allows=0, even though \\0 is a true Perl ref');

    # Plain unblessed scalars, exactly as YAML::PP::Load actually produces
    # them (not hand-picked stand-ins).
    my ($yaml_true, $yaml_false) = @{ YAML::PP::Load("- true\n- false\n") };
    is(inflate_props({ type => 'object', additionalProperties => $yaml_true })
        ->additionalProperties->allows, 1, "YAML::PP plain scalar '1' -> allows=1");
    is(inflate_props({ type => 'object', additionalProperties => $yaml_false })
        ->additionalProperties->allows, 0, "YAML::PP plain scalar '' -> allows=0");
};

# ============================================================================
# 5. No internal union-arm attribute name may leak into serialized output —
#    these are implementation detail, and upstream doesn't know them.
# ============================================================================

subtest 'no internal union-arm attribute name leaks into JSON or YAML output' => sub {
    my $crd = minimal_crd(combined_spec_schema());
    my $obj = $k8s->struct_to_object($CRD, $crd);

    my $encoded = $obj->to_json;
    my $yaml    = $obj->to_yaml;

    for my $arm (qw(allows value property schemas)) {
        unlike($encoded, qr/"\Q$arm\E"\s*:/, qq{JSON has no "$arm" key});
        unlike($yaml, qr/^\s*\Q$arm\E:/m, qq{YAML has no "$arm" key});
    }
};

# ============================================================================
# 6. A CRD using all four types round-trips losslessly, and a second pass
#    changes nothing.
# ============================================================================

subtest 'CRD combining all four union types round-trips losslessly and is idempotent' => sub {
    my $crd = minimal_crd(combined_spec_schema());

    my $obj1  = $k8s->struct_to_object($CRD, $crd);
    my $json1 = $obj1->to_json;

    my $reinflated = $k8s->inflate($json->decode($json1));
    my $json2       = $reinflated->to_json;
    is($json2, $json1, 'canonical JSON is identical after a full inflate/serialize round trip');

    my $reinflated_again = $k8s->inflate($json->decode($json2));
    my $json3             = $reinflated_again->to_json;
    is($json3, $json2, 'a second round trip changes nothing (idempotent)');

    # Spot-check each of the four arms individually, not just gross equality.
    my $spec_schema = $obj1->spec->versions->[0]->schema->openAPIV3Schema->properties->{spec};
    ok($spec_schema->properties->{tags}->items->is_schema, 'tags: single-schema arm preserved');
    ok(!$spec_schema->properties->{matrix}->items->is_schema, 'matrix: tuple arm preserved');
    ok(!$spec_schema->properties->{locked}->additionalProperties->is_schema, 'locked: boolean arm preserved');
    is($spec_schema->properties->{locked}->additionalProperties->allows, 0, 'locked stays false');
    ok(!$spec_schema->properties->{open}->additionalProperties->is_schema, 'open: boolean arm preserved');
    is($spec_schema->properties->{open}->additionalProperties->allows, 1, 'open stays true');
    ok(!$spec_schema->dependencies->{billingAddress}->is_schema, 'billingAddress: string-array arm preserved');
    ok($spec_schema->dependencies->{shipping}->is_schema, 'shipping: schema arm preserved');
};

# ============================================================================
# 7. `false` must not collapse into an empty schema object — the actual data
#    loss reported in the ticket, tested explicitly rather than as a
#    side-effect of another test.
# ============================================================================

subtest "additionalProperties: false does not collapse into an empty schema object" => sub {
    my $obj = inflate_props({ type => 'object', additionalProperties => JSON::MaybeXS::false });
    my $out = $obj->TO_JSON->{additionalProperties};

    isnt(ref($out), 'HASH', 'additionalProperties is not a hashref');
    is(json_scalar($out), 'false', 'additionalProperties encodes as the JSON literal false, not {}');

    # And through the full CRD -> JSON string path.
    my $crd = minimal_crd(properties => {
        locked => { type => 'object', additionalProperties => JSON::MaybeXS::false },
    });
    my $encoded = $k8s->struct_to_object($CRD, $crd)->to_json;
    like($encoded, qr/"additionalProperties":false/, 'false survives all the way to serialized CRD JSON');
    unlike($encoded, qr/"additionalProperties":\{\}/, 'false never becomes an empty object');
};

done_testing;
