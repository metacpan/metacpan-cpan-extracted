#!/usr/bin/env perl
# k179: a field typed as one of the apiextensions union classes -- V1::JSON
# (values of a K3s HelmChart, default/example/enum of a schema) or
# JSONSchemaPropsOr{Array,Bool,StringArray} (items, additionalProperties,
# additionalItems, dependencies) -- took a value of every shape on the
# inflate path, where IO::K8s hands anything to the class's FROM_STRUCT, but
# only a hashref on the constructor and setter path: the object coercers in
# IO::K8s::Resource passed nothing but a hash on to inflation, so
#
#     HelmChartSpec->new(values => [1, 2])
#     HelmChartSpec->new(values => 5)
#     JSONSchemaProps->new(enum => ['a'])
#     $chart->spec_set('values', [1, 2])
#
# all died on the field's InstanceOf type check although inflate accepts the
# very same values.
#
# Approved contract:
#   * for a target class with FROM_STRUCT (the union classes), the object
#     coercers -- single field, array of objects, hash of objects -- hand
#     every defined value to FROM_STRUCT, through the same call inflation
#     makes, not only a hashref; the constructor, the setter and the
#     SpecBuilder writes therefore take what inflate takes and serialize it
#     the same way -- checked on the wire JSON;
#   * an object already of the target class passes through untouched, and
#     undef stays "no value";
#   * a value the union itself refuses (a plain scalar for the items schema
#     arm) fails with the union's inflation error, as it does on inflate;
#   * for every other class the k146 rule stays: a defined value that is not
#     a hashref is left to the type constraint and refused.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr );
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::K3s::V1::HelmChart;
use IO::K8s::K3s::V1::HelmChartSpec;
use IO::K8s::Api::Core::V1::Pod;
use IO::K8s::Api::Core::V1::PodSpec;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps;

my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1);
my $k8s  = IO::K8s->new;

my $V1       = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::';
my $JSON_VAL = $V1.'JSON';
my $PROPS    = $V1.'JSONSchemaProps';
my $CHART    = 'IO::K8s::K3s::V1::HelmChartSpec';

sub wire { $json->encode($_[0]->TO_JSON) }

# The wire JSON the inflate path builds from the same struct -- the
# reference every constructor result below is compared against.
sub inflated { wire($k8s->struct_to_object('+'.$_[0], $_[1])) }

# ===========================================================================
# V1::JSON through a single object field (HelmChartSpec values)
# ===========================================================================

# Claim: ->new takes every JSON shape for a V1::JSON field and serializes it
# bare, exactly as inflate does.
subtest 'new: values takes an array, a number, a string, a boolean' => sub {
    my @cases = (
        [ 'an array',      [ 1, 2 ],               '{"values":[1,2]}' ],
        [ 'a number',      5,                      '{"values":5}' ],
        [ 'a string',      'plain',                '{"values":"plain"}' ],
        [ 'a JSON true',   JSON::MaybeXS::true(),  '{"values":true}' ],
        [ 'a hash, as before', { replicaCount => 3 }, '{"values":{"replicaCount":3}}' ],
    );
    for my $case (@cases) {
        my ($label, $value, $expect) = @$case;
        my $spec = eval { $CHART->new(values => $value) };
        is($@, '', $label.': constructs');
        next unless $spec;
        isa_ok($spec->values, $JSON_VAL, $label.': the field');
        is(wire($spec), $expect, $label.': wire JSON');
        is(wire($spec), inflated($CHART, { values => $value }), $label.': same as inflate');
    }
};

# Claim: the setter takes the same values as the constructor.
subtest 'setter: values([1, 2]) and values(5)' => sub {
    my $spec = $CHART->new;
    eval { $spec->values([ 1, 2 ]) };
    is($@, '', 'an array through the setter');
    is(wire($spec), '{"values":[1,2]}', 'wire JSON');
    eval { $spec->values(5) };
    is($@, '', 'a number through the setter');
    is(wire($spec), '{"values":5}', 'wire JSON');
};

# Claim: an object already of the class is kept as it is, not wrapped a
# second time, and undef is still "no value".
subtest 'an object of the class passes through; undef stays absent' => sub {
    my $value = $JSON_VAL->new(value => [ 1 ]);
    my $spec  = $CHART->new(values => $value);
    is(refaddr($spec->values), refaddr($value), 'the same object');
    is(wire($spec), '{"values":[1]}', 'not wrapped twice');

    my $empty = $CHART->new(values => undef);
    ok(!defined $empty->values, 'undef: no value');
    is(wire($empty), '{}', 'undef: omitted on the wire');
};

# Claim: spec_set writes a non-hash value into a union field (k179 names
# spec_set('values', [1, 2]) explicitly).
subtest 'spec_set: values takes an array and a number' => sub {
    my $chart = IO::K8s::K3s::V1::HelmChart->new(metadata => { name => 'traefik' }, spec => {});
    eval { $chart->spec_set('values', [ 1, 2 ]) };
    is($@, '', 'spec_set with an array');
    is($json->encode($chart->TO_JSON->{spec}), '{"values":[1,2]}', 'wire JSON');
    eval { $chart->spec_set('values', 5) };
    is($@, '', 'spec_set with a number');
    is($json->encode($chart->TO_JSON->{spec}), '{"values":5}', 'wire JSON');
};

# ===========================================================================
# JSONSchemaProps: every union field, single, array and map
# ===========================================================================

# Claim: each union field of a schema takes on ->new what inflate takes --
# including the array of V1::JSON behind enum and the map of
# JSONSchemaPropsOrStringArray behind dependencies.
subtest 'new: the union fields of JSONSchemaProps' => sub {
    my @cases = (
        [ 'enum of scalars',              { enum => [ 'a', 1 ] },                 '{"enum":["a",1]}' ],
        [ 'default a string',             { default => 'nginx' },                 '{"default":"nginx"}' ],
        [ 'example an array',             { example => [ 'x' ] },                 '{"example":["x"]}' ],
        [ 'items the array arm',          { items => [ { type => 'string' } ] },  '{"items":[{"type":"string"}]}' ],
        [ 'items the schema arm',         { items => { type => 'string' } },      '{"items":{"type":"string"}}' ],
        [ 'additionalProperties false',   { additionalProperties => JSON::MaybeXS::false() }, '{"additionalProperties":false}' ],
        [ 'additionalItems a plain 0',    { additionalItems => 0 },               '{"additionalItems":false}' ],
        [ 'dependencies, both arms',      { dependencies => { a => [ 'b' ], c => { type => 'object' } } },
          '{"dependencies":{"a":["b"],"c":{"type":"object"}}}' ],
    );
    for my $case (@cases) {
        my ($label, $args, $expect) = @$case;
        my $props = eval { $PROPS->new(%$args) };
        is($@, '', $label.': constructs');
        next unless $props;
        is(wire($props), $expect, $label.': wire JSON');
        is(wire($props), inflated($PROPS, $args), $label.': same as inflate');
    }
};

# Claim: in an array of union objects, elements that are already objects
# stay as they are and the others are built -- the array coercer's rule is
# the single field's rule, element by element.
subtest 'enum mixing objects and plain values' => sub {
    my $kept  = $JSON_VAL->new(value => 'kept');
    my $props = $PROPS->new(enum => [ $kept, 'built', 2 ]);
    is(refaddr($props->enum->[0]), refaddr($kept), 'the object element is the same object');
    isa_ok($props->enum->[$_], $JSON_VAL, 'element '.$_) for 1, 2;
    is(wire($props), '{"enum":["kept","built",2]}', 'wire JSON');
};

# Claim: spec_push and an indexed spec_set into an array of union objects
# build the elements the same way (the collection check runs the field's
# own coercion, k147).
subtest 'spec_push and spec_set into enum on a CRD' => sub {
    my $crd = IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition->new(
        metadata => { name => 'widgets.k179.example.com' },
        spec     => {
            group    => 'k179.example.com',
            names    => { kind => 'Widget', plural => 'widgets' },
            scope    => 'Namespaced',
            versions => [ { name => 'v1', served => 1, storage => 1,
                            schema => { openAPIV3Schema => { type => 'string' } } } ],
        },
    );
    my $path = 'versions.0.schema.openAPIV3Schema.enum';
    eval { $crd->spec_push($path, 'small', 'large') };
    is($@, '', 'spec_push of plain values');
    eval { $crd->spec_set($path.'.-1', 'huge') };
    is($@, '', 'indexed spec_set of a plain value');
    is($json->encode($crd->TO_JSON->{spec}{versions}[0]{schema}{openAPIV3Schema}),
        '{"enum":["small","huge"],"type":"string"}', 'wire JSON');
};

# Claim: a value the union itself refuses fails with the union's own
# inflation error, the one inflate gives for the same value.
subtest 'a value the union refuses: its inflation error' => sub {
    my $refused = qr/Cannot inflate \Q$PROPS\E: expected a hash \(a JSON object\), got a plain scalar/;
    eval { $PROPS->new(items => 5) };
    like($@, $refused, 'new: items => 5');
    eval { $k8s->struct_to_object('+'.$PROPS, { items => 5 }) };
    like($@, $refused, 'inflate: the same error');
};

# ===========================================================================
# GUARD: every other class keeps the k146 rule
# ===========================================================================

# Claim: only a class with FROM_STRUCT takes non-hash values; a normal
# nested class still refuses them through its type constraint.
subtest 'GUARD: a normal object field still refuses a non-hash' => sub {
    eval { IO::K8s::Api::Core::V1::Pod->new(spec => []) };
    like($@, qr/did not pass type constraint "Maybe\[InstanceOf\["IO::K8s::Api::Core::V1::PodSpec"\]\]"/,
        'Pod spec => []');
    eval { IO::K8s::Api::Core::V1::Pod->new(spec => 'x') };
    like($@, qr/did not pass type constraint/, 'Pod spec => "x"');
    eval { IO::K8s::Api::Core::V1::PodSpec->new(containers => [ 'x' ]) };
    like($@, qr/did not pass type constraint "ArrayRef\[InstanceOf\["IO::K8s::Api::Core::V1::Container"\]\]"/,
        'PodSpec containers => ["x"]');
};

done_testing;
