#!/usr/bin/env perl
# k172: IO::K8s::Role::SpecBuilder lost writes through a field whose value is
# an apiextensions union class. On a K3s HelmChart, spec.values is a
# V1::JSON -- a class that serializes as the bare value it holds, so on the
# wire `values` is just a JSON object. spec_set('values.replicaCount', 3)
# walked onto the V1::JSON object, found no declared field 'replicaCount'
# and wrote the value into the object's _unknown_fields bag, which that
# class's TO_JSON never reads: the chart serialized `values: null`. Writes
# into spec_hash('values') went into the object's own hash slots and were
# lost the same way, and spec_get('values.a') read the bag and returned
# undef. The JSONSchemaPropsOr{Array,Bool,StringArray} unions -- items,
# additionalProperties, additionalItems, dependencies of a schema -- had
# the same hole.
#
# Claims:
#   * a spec path walks through a union into the value it holds: a V1::JSON
#     into its value, a JSONSchemaPropsOr* into the arm in use (the schema,
#     or the array);
#   * spec_set, spec_get, spec_hash, spec_array, spec_push and spec_delete
#     all reach that value, and the writes arrive in the wire JSON --
#     checked on the JSON text;
#   * an unset or empty union is vivified holding what the next segment
#     asks for: a hash (a schema arm) for a key, an array for an index --
#     and a union that cannot hold that croaks before anything is stored;
#   * a value that is an array follows the free array rules (indexes, -1),
#     a scalar blocks the walk with the spec path in the message, as on
#     free JSON data;
#   * spec_get of the union field itself still returns the union object;
#   * set_values (spec.set) is unchanged, byte for byte.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();

use IO::K8s;

my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1);
my $k8s  = IO::K8s->new(with => ['IO::K8s::K3s']);

my $V1       = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::';
my $JSON_VAL = $V1.'JSON';

sub chart {
    my (%spec) = @_;
    return $k8s->new_object('HelmChart',
        metadata => { name => 'traefik', namespace => 'kube-system' },
        (%spec ? (spec => \%spec) : ()),
    );
}

sub spec_json { $json->encode($_[0]->TO_JSON->{spec}) }

# ===========================================================================
# V1::JSON: HelmChart spec.values
# ===========================================================================

subtest 'spec_set through values writes into the JSON value' => sub {
    my $chart = chart();
    $chart->spec_set('values.replicaCount', 3);
    is(spec_json($chart), '{"values":{"replicaCount":3}}',
        'a missing values is vivified as a hash and the key lands in it');
    $chart->spec_set('values.image.tag', 'v3.7.12');
    is(spec_json($chart), '{"values":{"image":{"tag":"v3.7.12"},"replicaCount":3}}',
        'a nested key vivifies a plain hash inside the value');
    like($chart->to_json, qr/"values":\{"image":\{"tag":"v3\.7\.12"\},"replicaCount":3\}/,
        'and the whole document carries it');
    ok(!%{ $chart->spec->values->_unknown_fields }, 'nothing went into the union\'s unknown-field bag');
};

subtest 'spec_get reads through values; the field itself is still the union object' => sub {
    my $chart = $k8s->inflate({
        apiVersion => 'helm.cattle.io/v1', kind => 'HelmChart',
        metadata   => { name => 'traefik', namespace => 'kube-system' },
        spec       => { values => { replicaCount => 3, image => { tag => 'v1' } } },
    });
    is($chart->spec_get('values.replicaCount'), 3, 'a top-level key of the value');
    is($chart->spec_get('values.image.tag'), 'v1', 'a nested key of the value');
    is($chart->spec_get('values.missing'), undef, 'a missing key is undef');
    is($chart->spec_get('values.image.tag.deeper'), undef, 'a path past a scalar is undef');
    isa_ok($chart->spec_get('values'), $JSON_VAL, 'spec_get of values itself');

    $chart->spec_set('values.image.tag', 'v2');
    is(spec_json($chart), '{"values":{"image":{"tag":"v2"},"replicaCount":3}}',
        'spec_set on an inflated value edits it in place');
};

subtest 'spec_hash hands out the live value container' => sub {
    my $chart = chart();
    my $values = $chart->spec_hash('values');
    is(ref $values, 'HASH', 'a plain hashref, not the union object');
    is(spec_json($chart), '{"values":{}}', 'a missing values is vivified as an empty hash');
    $values->{replicaCount} = 2;
    $values->{service} = { type => 'LoadBalancer' };
    is(spec_json($chart), '{"values":{"replicaCount":2,"service":{"type":"LoadBalancer"}}}',
        'writes into the returned hash arrive in the wire JSON');
    is($chart->spec_hash('values'), $values, 'a second call returns the same hash');
    is($chart->spec->values->value, $values, 'which is the value the union holds');

    my $service = $chart->spec_hash('values.service');
    $service->{port} = 80;
    like(spec_json($chart), qr/"service":\{"port":80,"type":"LoadBalancer"\}/,
        'spec_hash one level deeper is the nested hash itself');
};

subtest 'spec_array and spec_push reach an array inside the value' => sub {
    my $chart = chart();
    $chart->spec_push('values.ports', 8080, 'web');
    push @{ $chart->spec_array('values.ports') }, 443;
    is(spec_json($chart), '{"values":{"ports":[8080,"web",443]}}',
        'free JSON inside the value: the elements keep their JSON type');
};

subtest 'spec_delete removes a key of the value' => sub {
    my $chart = chart(values => { replicaCount => 3, image => { tag => 'v1', pullPolicy => 'Always' } });
    $chart->spec_delete('values.image.pullPolicy');
    is(spec_json($chart), '{"values":{"image":{"tag":"v1"},"replicaCount":3}}', 'a nested key');
    $chart->spec_delete('values.replicaCount');
    is(spec_json($chart), '{"values":{"image":{"tag":"v1"}}}', 'a top-level key');
    $chart->spec_delete('values.nothing.here');
    is(spec_json($chart), '{"values":{"image":{"tag":"v1"}}}', 'a path that does not resolve is a no-op');
    $chart->spec_delete('values');
    is(spec_json($chart), '{}', 'deleting values itself clears the field');
};

subtest 'an empty union (value undef) is vivified as a hash' => sub {
    my $chart = chart(values => $JSON_VAL->new);
    ok(!defined $chart->spec->values->value, 'the union holds no value');
    $chart->spec_set('values.a', 1);
    is(spec_json($chart), '{"values":{"a":1}}', 'spec_set');

    my $other = chart(values => $JSON_VAL->new);
    is(ref $other->spec_hash('values'), 'HASH', 'spec_hash');
    is(spec_json($other), '{"values":{}}', 'wire JSON after spec_hash');
};

subtest 'an array value follows the free array rules' => sub {
    my $chart = $k8s->inflate({
        apiVersion => 'helm.cattle.io/v1', kind => 'HelmChart',
        metadata   => { name => 'x', namespace => 'default' },
        spec       => { values => [ 1, 2 ] },
    });
    is($chart->spec_get('values.0'), 1, 'spec_get by index');
    is($chart->spec_get('values.-1'), 2, 'spec_get with -1');
    $chart->spec_set('values.-1', 3);
    $chart->spec_push('values', 4);
    is(spec_json($chart), '{"values":[1,3,4]}', 'spec_set by index, spec_push onto the value itself');
    is(ref $chart->spec_array('values'), 'ARRAY', 'spec_array of values is the array');
    is($chart->spec_hash('values'), $chart->spec_array('values'),
        'spec_hash hands out the same array, as on free JSON data');
    throws_ok { $chart->spec_set('values.a', 1) }
        qr/\Aspec path 'values\.a': 'a' is not an array index/, 'a key on an array croaks with the path';
    is(spec_json($chart), '{"values":[1,3,4]}', 'and changes nothing');

    my $fresh = chart();
    $fresh->spec_set('values.0', 'first');
    is(spec_json($fresh), '{"values":["first"]}', 'an index on a missing values vivifies an array');
};

subtest 'a scalar value blocks the walk, as on free JSON data' => sub {
    my $chart = $k8s->inflate({
        apiVersion => 'helm.cattle.io/v1', kind => 'HelmChart',
        metadata   => { name => 'x', namespace => 'default' },
        spec       => { values => 'plain' },
    });
    throws_ok { $chart->spec_set('values.a', 1) }
        qr/\Aspec path 'values\.a': cannot descend through scalar field 'values'/, 'spec_set';
    throws_ok { $chart->spec_hash('values') }
        qr/\Aspec path 'values': 'values' holds a scalar/, 'spec_hash';
    throws_ok { $chart->spec_array('values') }
        qr/\Aspec path 'values': 'values' holds a non-array value/, 'spec_array';
    is($chart->spec_get('values.a'), undef, 'spec_get is undef');
    is(spec_json($chart), '{"values":"plain"}', 'the value is untouched');
};

subtest 'spec_array on a hash value croaks' => sub {
    my $chart = chart(values => { a => 1 });
    throws_ok { $chart->spec_array('values') }
        qr/\Aspec path 'values': 'values' holds a non-array value/, 'non-array value';
};

subtest 'set_values (spec.set) is unchanged' => sub {
    my $chart = chart();
    $chart->set_values(replicas => 3, 'image.tag' => 'v1');
    is(spec_json($chart), '{"set":{"image.tag":"v1","replicas":3}}', 'spec.set, byte for byte');
    $chart->spec_set('values.replicaCount', 2);
    is(spec_json($chart), '{"set":{"image.tag":"v1","replicas":3},"values":{"replicaCount":2}}',
        'values and set side by side');
};

subtest 'HelmChartConfig spec.values the same way' => sub {
    my $cfg = $k8s->new_object('HelmChartConfig', metadata => { name => 'traefik', namespace => 'kube-system' });
    $cfg->spec_set('values.logs.general.level', 'DEBUG');
    is($json->encode($cfg->TO_JSON->{spec}), '{"values":{"logs":{"general":{"level":"DEBUG"}}}}',
        'nested vivification through HelmChartConfigSpec.values');
};

# ===========================================================================
# JSONSchemaPropsOr* and V1::JSON inside a schema
# ===========================================================================

{
    package TestK172::Schema;
    use IO::K8s::APIObject
        api_version     => 'k172.example.com/v1',
        resource_plural => 'schemas';
    k8s spec => '+IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps';
}

sub schema_json { $json->encode($_[0]->TO_JSON->{spec}) }

subtest 'items (JSONSchemaPropsOrArray): the schema arm' => sub {
    my $s = TestK172::Schema->new(spec => { type => 'array' });
    $s->spec_set('items.type', 'string');
    is(schema_json($s), '{"items":{"type":"string"},"type":"array"}', 'a key vivifies the schema arm');
    is($s->spec_get('items.type'), 'string', 'spec_get reads it back');
    $s->spec_set('items.maxLength', 63);
    is(schema_json($s), '{"items":{"maxLength":63,"type":"string"},"type":"array"}', 'a second key');
    $s->spec_delete('items.maxLength');
    is(schema_json($s), '{"items":{"type":"string"},"type":"array"}', 'spec_delete clears it');
};

subtest 'items (JSONSchemaPropsOrArray): the array arm' => sub {
    my $s = $k8s->struct_to_object('+TestK172::Schema', {
        spec => { type => 'array', items => [ { type => 'string' } ] },
    });
    is($s->spec_get('items.0.type'), 'string', 'spec_get into an element');
    $s->spec_set('items.0.type', 'integer');
    is(schema_json($s), '{"items":[{"type":"integer"}],"type":"array"}', 'spec_set into an element');
    throws_ok { $s->spec_set('items.1', { type => 'boolean' }) }
        qr/\Aspec path 'items\.1': cannot set '1' in 'items'/,
        'a plain hash is refused where the arm holds schema objects';
    is(schema_json($s), '{"items":[{"type":"integer"}],"type":"array"}', 'and nothing is stored');
};

subtest 'additionalProperties (JSONSchemaPropsOrBool)' => sub {
    my $s = TestK172::Schema->new(spec => { type => 'object' });
    $s->spec_set('additionalProperties.type', 'integer');
    is(schema_json($s), '{"additionalProperties":{"type":"integer"},"type":"object"}',
        'a key vivifies the schema arm');

    my $closed = $k8s->struct_to_object('+TestK172::Schema', {
        spec => { type => 'object', additionalProperties => JSON::MaybeXS::false() },
    });
    throws_ok { $closed->spec_set('additionalProperties.type', 'x') }
        qr/\Aspec path 'additionalProperties\.type': cannot descend through scalar field 'additionalProperties'/,
        'the boolean arm blocks the walk like a scalar';
    is($closed->spec_get('additionalProperties.type'), undef, 'spec_get past it is undef');
    is(schema_json($closed), '{"additionalProperties":false,"type":"object"}', 'false stays false');

    my $unset = TestK172::Schema->new(spec => { type => 'object' });
    throws_ok { $unset->spec_set('additionalProperties.0', 'x') }
        qr/\Aspec path 'additionalProperties\.0': cannot create \S+JSONSchemaPropsOrBool for 'additionalProperties': it cannot hold an array/,
        'an index on an unset boolean-or-schema union croaks';
    is(schema_json($unset), '{"type":"object"}', 'before anything is stored');
};

subtest 'dependencies (hash of JSONSchemaPropsOrStringArray)' => sub {
    my $s = TestK172::Schema->new(spec => { type => 'object' });
    $s->spec_push('dependencies.creditCard', 'billingAddress');
    $s->spec_set('dependencies.shipping.type', 'object');
    is(schema_json($s),
        '{"dependencies":{"creditCard":["billingAddress"],"shipping":{"type":"object"}},"type":"object"}',
        'an array value vivifies the string-array arm, a key the schema arm');
    throws_ok { $s->spec_push('dependencies.creditCard', [ 'nested' ]) }
        qr/\Aspec path 'dependencies\.creditCard': cannot push onto 'creditCard'/,
        'the string-array arm checks what is pushed onto it';
};

subtest 'default / example (V1::JSON) inside a schema' => sub {
    my $s = TestK172::Schema->new(spec => { type => 'object' });
    $s->spec_set('default.replicas', 1);
    $s->spec_set('example.0', 'x');
    is(schema_json($s), '{"default":{"replicas":1},"example":["x"],"type":"object"}',
        'a key vivifies a hash value, an index an array value');
    is($s->spec_get('default.replicas'), 1, 'spec_get reads through default');
};

{
    package TestK172::Opaque;
    use IO::K8s::APIObject
        api_version     => 'k172.example.com/v1',
        resource_plural => 'opaques';
    k8s spec => '+IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON';
}

subtest 'a spec that is itself a V1::JSON' => sub {
    my $o = TestK172::Opaque->new;
    $o->spec_set('a.b', 1);
    $o->spec_merge(c => 2);
    is($json->encode($o->TO_JSON->{spec}), '{"a":{"b":1},"c":2}', 'spec_set and spec_merge into the value');
    is($o->spec_get('a.b'), 1, 'spec_get');
};

done_testing;
