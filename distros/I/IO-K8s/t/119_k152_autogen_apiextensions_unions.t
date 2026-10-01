#!/usr/bin/env perl
# k152: an openapi_spec handed to IO::K8s carries the apiextensions
# definitions ...v1.JSON and ...v1.JSONSchemaPropsOr{Array,Bool,StringArray}
# the way upstream ships them: a description and nothing else, since each
# stands for a value that is not a JSON object (any JSON value; a schema or
# an array of schemas; a schema or a boolean; a schema or a string array).
# IO::K8s::AutoGen generated a normal, field-less class for each. That class
# has no FROM_STRUCT, so `default: "foo"` was silently inflated to {} before
# k146 and has been refused loudly since -- either way the value could not
# round-trip.
#
# Claims:
#   * a $ref to one of the four v1 names -- as a property, as array items,
#     as map values -- is typed as the shipped union class (the one with
#     FROM_STRUCT), whatever reuse_core says, and no normal class is
#     generated for the definition;
#   * every arm of every union round-trips unchanged to the wire JSON: a
#     string, a numeric string, numbers, a boolean, an array, an object, a
#     schema, an array of schemas, a string array;
#   * the v1beta1 names, for which IO::K8s ships no classes, are carried
#     opaquely by the v1 JSON class (value in, same value out) instead of
#     becoming a normal class;
#   * the names resolve without the definitions in the spec, like the
#     apimachinery scalars (IntOrString, Quantity, Time) and the %OPAQUE_TYPES
#     names do -- no unresolved-$ref refusal for a type IO::K8s already knows.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::AutoGen;

my $json = JSON::MaybeXS->new(canonical => 1, utf8 => 1);
my $APIEXT = 'io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.';
my $SHIPPED = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::';
my @UNIONS = qw( JSON JSONSchemaPropsOrArray JSONSchemaPropsOrBool JSONSchemaPropsOrStringArray );

sub ref_to { return { '$ref' => '#/definitions/' . $APIEXT . $_[0] } }

# The widget schema: every union at each position a $ref can take.
sub widget_def {
    my ($version, $kind) = @_;
    return {
        type => 'object',
        'x-kubernetes-group-version-kind' =>
            [{ group => 'k152.example.com', version => 'v1', kind => $kind }],
        properties => {
            apiVersion => { type => 'string' },
            kind       => { type => 'string' },
            value      => ref_to("$version.JSON"),
            values     => { type => 'array', items => ref_to("$version.JSON") },
            byName     => { type => 'object', additionalProperties => ref_to("$version.JSON") },
            items      => ref_to("$version.JSONSchemaPropsOrArray"),
            allowed    => ref_to("$version.JSONSchemaPropsOrBool"),
            deps       => { type => 'object',
                            additionalProperties => ref_to("$version.JSONSchemaPropsOrStringArray") },
        },
    };
}

# The union definitions as upstream's swagger.json carries them.
sub union_defs {
    my ($version) = @_;
    return map { ( "$APIEXT$version.$_" => { description => "$_ as upstream describes it." } ) } @UNIONS;
}

sub spec_for {
    my ($version, $kind, %opt) = @_;
    return { definitions => {
        "com.example.k152.v1.$kind" => widget_def($version, $kind),
        $opt{without_unions} ? () : union_defs($version),
    } };
}

# Canonical JSON of what went in, and of what came out of to_json.
sub wire_is {
    my ($obj, $doc, $label) = @_;
    is($json->encode($json->decode($obj->to_json)), $json->encode($doc), $label);
}

# Every arm of every union, as JSON text so the scalars keep their JSON type.
my @documents = (
    [ 'a string'            => '{"value":"foo"}' ],
    [ 'a numeric string'    => '{"value":"42"}' ],
    [ 'an integer'          => '{"value":42}' ],
    [ 'a fraction'          => '{"value":1.5}' ],
    [ 'a boolean'           => '{"value":false}' ],
    [ 'an array'            => '{"value":[1,"a",true,{"b":null}]}' ],
    [ 'an object'           => '{"value":{"a":{"b":[1,2]}}}' ],
    [ 'an array of any'     => '{"values":["foo",7,true,[1],{"x":"y"}]}' ],
    [ 'a map of any'        => '{"byName":{"a":"foo","b":2.5,"c":false,"d":{"e":1}}}' ],
    [ 'one schema'          => '{"items":{"type":"string","minLength":1}}' ],
    [ 'a schema array'      => '{"items":[{"type":"string"},{"type":"integer"}]}' ],
    [ 'the boolean true'    => '{"allowed":true}' ],
    [ 'the boolean false'   => '{"allowed":false}' ],
    [ 'a schema for Or-Bool' => '{"allowed":{"type":"object","x-kubernetes-preserve-unknown-fields":true}}' ],
    [ 'a string array'      => '{"deps":{"a":["b","c"]}}' ],
    [ 'a schema for Or-StringArray' => '{"deps":{"a":{"required":["b"],"type":"object"}}}' ],
);

subtest 'v1 union $refs are typed as the shipped FROM_STRUCT classes' => sub {
    my $k8s = IO::K8s->new(openapi_spec => spec_for('v1', 'Widget'));
    my $obj = $k8s->inflate({ apiVersion => 'k152.example.com/v1', kind => 'Widget' });
    my $info = ref($obj)->_k8s_attr_info;

    is($info->{value}{class},  $SHIPPED.'JSON', 'property $ref -> the shipped JSON class');
    ok($info->{value}{is_object}, '... as a single object field');
    is($info->{values}{class}, $SHIPPED.'JSON', 'items $ref -> the shipped JSON class');
    ok($info->{values}{is_array_of_objects}, '... as an array of them');
    is($info->{byName}{class}, $SHIPPED.'JSON', 'additionalProperties $ref -> the shipped JSON class');
    ok($info->{byName}{is_hash_of_objects}, '... as a map of them');
    is($info->{items}{class},   $SHIPPED.'JSONSchemaPropsOrArray',       'JSONSchemaPropsOrArray');
    is($info->{allowed}{class}, $SHIPPED.'JSONSchemaPropsOrBool',        'JSONSchemaPropsOrBool');
    is($info->{deps}{class},    $SHIPPED.'JSONSchemaPropsOrStringArray', 'JSONSchemaPropsOrStringArray');
    ok($_->can('FROM_STRUCT'), "$_ inflates through FROM_STRUCT")
        for map { $SHIPPED.$_ } @UNIONS;

    my @generated = grep { /apiextensions/ } IO::K8s::AutoGen::generated_classes();
    is_deeply(\@generated, [], 'no normal class is generated for any union definition');
};

subtest 'every union arm round-trips unchanged to the wire JSON' => sub {
    my $k8s = IO::K8s->new(openapi_spec => spec_for('v1', 'Widget'));
    for my $case (@documents) {
        my ($label, $text) = @$case;
        my $doc = $json->decode($text);
        @$doc{qw(apiVersion kind)} = ('k152.example.com/v1', 'Widget');
        my $obj;
        lives_ok { $obj = $k8s->inflate($json->encode($doc)) } "$label inflates";
        next unless $obj;
        wire_is($obj, $doc, "$label comes back unchanged");
    }
};

subtest 'reuse_core => 0 does not turn the unions back into normal classes' => sub {
    my $spec = spec_for('v1', 'Gadget');
    my $class = IO::K8s::AutoGen::get_or_generate(
        'com.example.k152.v1.Gadget', $spec->{definitions}{'com.example.k152.v1.Gadget'},
        $spec->{definitions}, 'IO::K8s::_AUTOGEN_k152_noreuse',
        api_version => 'k152.example.com/v1', kind => 'Gadget', reuse_core => 0);
    is($class->_k8s_attr_info->{value}{class}, $SHIPPED.'JSON',
        'the shipped JSON class with reuse_core off');
    my $obj = IO::K8s->new->struct_to_object("+$class", { value => 'foo', allowed => \0 });
    is($obj->TO_JSON->{value}, 'foo', 'value: "foo" survives with reuse_core off');
};

subtest 'v1beta1 unions are carried opaquely by the v1 JSON class' => sub {
    my $k8s = IO::K8s->new(openapi_spec => spec_for('v1beta1', 'OldWidget'));
    my $obj = $k8s->inflate({ apiVersion => 'k152.example.com/v1', kind => 'OldWidget' });
    my $info = ref($obj)->_k8s_attr_info;
    is($info->{$_}{class}, $SHIPPED.'JSON', "v1beta1 $_ -> the opaque v1 JSON carrier")
        for qw( value values byName items allowed deps );

    for my $case (@documents) {
        my ($label, $text) = @$case;
        my $doc = $json->decode($text);
        @$doc{qw(apiVersion kind)} = ('k152.example.com/v1', 'OldWidget');
        my $got;
        lives_ok { $got = $k8s->inflate($json->encode($doc)) } "v1beta1: $label inflates";
        next unless $got;
        wire_is($got, $doc, "v1beta1: $label comes back unchanged");
    }
};

subtest 'the union names resolve without their definitions in the spec' => sub {
    my $k8s = IO::K8s->new(openapi_spec => spec_for('v1', 'Bare', without_unions => 1));
    my $obj;
    lives_ok {
        $obj = $k8s->inflate({ apiVersion => 'k152.example.com/v1', kind => 'Bare',
            value => 'foo', items => [ { type => 'string' } ] });
    } 'no unresolved-$ref refusal for a known apiextensions union';
    is($obj->TO_JSON->{value}, 'foo', 'value round-trips');
    is_deeply($obj->TO_JSON->{items}, [ { type => 'string' } ], 'schema array round-trips');
};

done_testing;
