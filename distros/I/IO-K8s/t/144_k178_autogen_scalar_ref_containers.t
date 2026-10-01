#!/usr/bin/env perl
# k178: IO::K8s::AutoGen typed a $ref to one of the apimachinery scalar
# types -- resource.Quantity, intstr.IntOrString, meta.v1.Time and
# meta.v1.MicroTime -- as those scalars only where the $ref sat on a
# property. The same $ref as an array's items or a map's
# additionalProperties went through the object path instead: the
# definition (a bare `type: string`) was generated as an empty class, and
# real data then failed with "expected a hash ... got a plain scalar" --
# or, without the definition in the spec, generation died on an
# unresolved $ref. Alongside, a date-time array element was checked by the
# strict RFC 3339 regex while the scalar Time of the same generated class
# accepted any string, so an element the API server stores as written
# (a lowercase 't' / 'z' is valid RFC 3339) failed to inflate.
#
# Claims:
#   * items with one of the four $refs become [Quantity] / [IntOrStr] /
#     [Time], additionalProperties { Quantity => 1 } / { IntOrStr => 1 } /
#     { Time => 1 } -- the container form of the scalar case -- whether or
#     not the spec ships the definitions, and no class is generated for them;
#   * real wire data inflates into those fields and goes back out with the
#     same values, checked on the JSON text, through ->new, from_json and
#     the inflate path;
#   * a generated Time accepts the same values as a scalar and as an array
#     element, from a $ref and from `format: date-time` alike -- the scalar
#     rule, any string, so a lowercase RFC 3339 timestamp inflates; a
#     generated Quantity array element follows its scalar the same way; the
#     shipped [Time] / [Quantity] keep their strict check;
#   * a map default is checked per value, as the DSL checks it, not dropped
#     for being a hash;
#   * the reuse check reads these $refs the way the generator now types
#     them, so a definition shaped like a shipped class with typed scalar
#     arrays or maps can reuse it (the k148 mirror rule).
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::AutoGen;
use IO::K8s::Api::Resource::V1::CapacityRequestPolicy;

my $json = JSON::MaybeXS->new(canonical => 1, utf8 => 1);

my $Q  = '#/definitions/io.k8s.apimachinery.pkg.api.resource.Quantity';
my $IS = '#/definitions/io.k8s.apimachinery.pkg.util.intstr.IntOrString';
my $T  = '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.Time';
my $MT = '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.MicroTime';

# The four definitions as the upstream swagger ships them: scalars.
my %scalar_defs = (
    'io.k8s.apimachinery.pkg.api.resource.Quantity'   => { type => 'string' },
    'io.k8s.apimachinery.pkg.util.intstr.IntOrString' => { type => 'string', format => 'int-or-string' },
    'io.k8s.apimachinery.pkg.apis.meta.v1.Time'       => { type => 'string', format => 'date-time' },
    'io.k8s.apimachinery.pkg.apis.meta.v1.MicroTime'  => { type => 'string', format => 'date-time' },
);

my $schema = {
    type       => 'object',
    properties => {
        quantities => { type => 'array',  items => { '$ref' => $Q } },
        ports      => { type => 'array',  items => { '$ref' => $IS } },
        stamps     => { type => 'array',  items => { '$ref' => $T } },
        microStamps => { type => 'array', items => { '$ref' => $MT } },
        usage      => { type => 'object', additionalProperties => { '$ref' => $Q } },
        portMap    => { type => 'object', additionalProperties => { '$ref' => $IS } },
        stampMap   => { type => 'object', additionalProperties => { '$ref' => $T } },
        # the scalar forms, for the one-rule comparison
        stamp      => { '$ref' => $T },
        amount     => { '$ref' => $Q },
        crdStamp   => { type => 'string', format => 'date-time' },
        crdStamps  => { type => 'array', items => { type => 'string', format => 'date-time' } },
    },
};

my $ns = 'IO::K8s::_AUTOGEN_k178';
my $class = IO::K8s::AutoGen::get_or_generate(
    'com.example.v1.K178Thing', $schema, { %scalar_defs }, $ns);

subtest 'scalar $refs in items and additionalProperties get the container form' => sub {
    my $info = $class->_k8s_attr_info;
    ok($info->{quantities}{is_array_of_quantity},        'items $ref Quantity: [Quantity]');
    ok($info->{ports}{is_array_of_int_or_string},        'items $ref IntOrString: [IntOrStr]');
    ok($info->{stamps}{is_array_of_time},                'items $ref Time: [Time]');
    ok($info->{microStamps}{is_array_of_time},           'items $ref MicroTime: [Time]');
    ok($info->{usage}{is_hash_of_quantity},              'additionalProperties $ref Quantity: { Quantity => 1 }');
    ok($info->{portMap}{is_hash_of_int_or_string},       'additionalProperties $ref IntOrString: { IntOrStr => 1 }');
    ok($info->{stampMap}{is_hash_of_time},               'additionalProperties $ref Time: { Time => 1 }');
    ok(!$info->{$_}{is_array_of_objects}, "$_ is not an array of objects")
        for qw( quantities ports stamps microStamps );
    ok(!$info->{$_}{is_hash_of_objects}, "$_ is not a map of objects")
        for qw( usage portMap stampMap );
    my @empty = grep { /::(Quantity|IntOrString|Time|MicroTime)\z/ }
        IO::K8s::AutoGen::generated_classes();
    is_deeply(\@empty, [], 'no class is generated for the scalar definitions');
};

subtest 'the definitions need not be in the spec' => sub {
    my $gen;
    lives_ok {
        $gen = IO::K8s::AutoGen::get_or_generate('com.example.v1.K178Bare', {
            type       => 'object',
            properties => {
                quantities => { type => 'array',  items => { '$ref' => $Q } },
                usage      => { type => 'object', additionalProperties => { '$ref' => $Q } },
            },
        }, {}, 'IO::K8s::_AUTOGEN_k178_bare');
    } 'no unresolved-$ref refusal: the names resolve like the property-level $ref';
    my $info = $gen->_k8s_attr_info;
    ok($info->{quantities}{is_array_of_quantity}, 'items: [Quantity]');
    ok($info->{usage}{is_hash_of_quantity},       'additionalProperties: { Quantity => 1 }');
};

subtest 'real wire data inflates and round-trips' => sub {
    my $doc = '{"microStamps":["2026-09-27T12:00:00.123456Z"],'
        . '"portMap":{"a":8080,"b":"http"},"ports":[8080,"25%"],'
        . '"quantities":["1Gi","500m"],"stampMap":{"at":"2026-09-27T12:00:00Z"},'
        . '"stamps":["2026-09-27T12:00:00Z"],"usage":{"cpu":"250m","memory":"64Mi"}}';

    my $from_json;
    lives_ok { $from_json = $class->from_json($doc) } 'from_json takes the scalar values';
    is($from_json->to_json, $doc, 'from_json -> to_json writes the same document');

    my $via_struct;
    lives_ok { $via_struct = IO::K8s->new->struct_to_object("+$class", $json->decode($doc)) }
        'struct_to_object (the inflate path) takes them too';
    is($via_struct->to_json, $doc, 'struct_to_object -> to_json writes the same document');

    my $obj = $class->new(quantities => ['1Gi'], usage => { cpu => '250m' });
    is($obj->to_json, '{"quantities":["1Gi"],"usage":{"cpu":"250m"}}', '->new');
    is_deeply($obj->quantities, ['1Gi'], 'a [Quantity] element is the plain scalar');
};

subtest 'a generated Time follows one rule, scalar and array alike' => sub {
    # RFC 3339 allows a lowercase 't' and 'z'; the API server stores a
    # custom resource's date-time string as written.
    my $lower = '2026-09-27t12:00:00z';
    lives_ok { $class->new(stamp => $lower) }    'scalar $ref Time takes a lowercase timestamp';
    lives_ok { $class->new(stamps => [$lower]) } 'items $ref Time take it too';
    lives_ok { $class->new(crdStamp => $lower) } 'scalar format: date-time takes it';
    lives_ok { $class->new(crdStamps => [$lower]) } 'items format: date-time take it too';
    is($class->new(crdStamps => [$lower])->to_json, '{"crdStamps":["' . $lower . '"]}',
        'and it goes out unchanged');

    # The scalar rule is any string; an element now follows it.
    lives_ok { $class->new(stamp => 'yesterday') }       'the scalar never checked the format';
    lives_ok { $class->new(crdStamps => ['yesterday']) } 'an array element no longer does either';
    lives_ok { $class->new(amount => 'lots') }           'nor does a generated scalar Quantity';
    lives_ok { $class->new(quantities => ['lots']) }     '... or a generated [Quantity] element';
    throws_ok { $class->new(crdStamps => [ {} ]) } qr/crdStamps/,
        'a reference is still no Time element';

    # A hand-written class keeps the strict library types.
    {
        package TestK178::Strict;
        use IO::K8s::Resource;
        k8s times      => [Time];
        k8s quantities => [Quantity];
    }
    throws_ok { TestK178::Strict->new(times => [$lower]) } qr/RFC3339/,
        'a shipped [Time] still refuses a lowercase timestamp';
    throws_ok { TestK178::Strict->new(quantities => ['lots']) } qr/Quantity/,
        'a shipped [Quantity] still refuses a non-quantity';
};

subtest 'defaults on the container forms' => sub {
    my $gen;
    lives_ok {
        $gen = IO::K8s::AutoGen::get_or_generate('com.example.v1.K178Defaults', {
            type       => 'object',
            properties => {
                usage    => { type => 'object', additionalProperties => { '$ref' => $Q },
                              default => { cpu => '1', memory => '1Gi' } },
                badUsage => { type => 'object', additionalProperties => { '$ref' => $Q },
                              default => { cpu => 'lots' } },
                notAMap  => { type => 'object', additionalProperties => { '$ref' => $Q },
                              default => '1' },
                stamps   => { type => 'array', items => { type => 'string', format => 'date-time' },
                              default => ['2026-09-27t12:00:00z'] },
                refStamps => { type => 'array', items => { '$ref' => $T },
                              default => [ {} ] },
            },
        }, { %scalar_defs }, 'IO::K8s::_AUTOGEN_k178_defaults');
    } 'container defaults do not fail class generation';
    my $info = $gen->_k8s_attr_info;
    is_deeply($info->{usage}{options}{default}, { cpu => '1', memory => '1Gi' },
        'a map default whose values are quantities is kept');
    ok(!exists $info->{badUsage}{options}{default},
        'a map default with a value the map rejects is dropped');
    ok(!exists $info->{notAMap}{options}{default}, 'a map default that is no hash is dropped');
    is_deeply($info->{stamps}{options}{default}, ['2026-09-27t12:00:00z'],
        'a date-time array default follows the element rule: a lowercase timestamp is kept');
    ok(!exists $info->{refStamps}{options}{default},
        'an array default with an element no Time can hold is dropped');
};

subtest 'the reuse check reads these $refs the way the generator types them' => sub {
    # Core::V1::VolumeResourceRequirements is {limits, requests}, both
    # { Quantity => 1 }. A definition of that shape whose maps $ref the
    # Quantity definition reuses it now; before, the map values read as the
    # empty object class and nothing matched.
    my $gen = IO::K8s::AutoGen::get_or_generate('com.example.v1.K178Reuse', {
        type       => 'object',
        properties => {
            resources => {
                type       => 'object',
                properties => {
                    limits   => { type => 'object', additionalProperties => { '$ref' => $Q } },
                    requests => { type => 'object', additionalProperties => { '$ref' => $Q } },
                },
            },
        },
    }, { %scalar_defs }, 'IO::K8s::_AUTOGEN_k178_reuse');
    is($gen->_k8s_attr_info->{resources}{class}, 'IO::K8s::Api::Core::V1::VolumeResourceRequirements',
        'a {limits, requests} map pair of Quantity $refs reuses VolumeResourceRequirements');

    # Items: the element check the generator mirrors, on a shipped [Quantity].
    my $entry = IO::K8s::Api::Resource::V1::CapacityRequestPolicy->_k8s_attr_info->{validValues};
    my $ctx = { defs => { %scalar_defs }, active => {} };
    ok(IO::K8s::AutoGen::_field_compatible($entry, { type => 'array', items => { '$ref' => $Q } }, $ctx),
        'items $ref Quantity are compatible with a shipped [Quantity]');
};

done_testing;
