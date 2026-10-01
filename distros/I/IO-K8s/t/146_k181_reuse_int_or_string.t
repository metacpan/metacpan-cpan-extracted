#!/usr/bin/env perl
# k181: AutoGen's core-class reuse check (D5, k148) read an int-or-string
# schema as the 'string' kind, and 'string' is compatible with a Str field.
# So a CRD struct {name: string, value: int-or-string} reused
# Core::V1::HTTPHeader, whose value is Str, and {key, operator, values}
# with int-or-string items reused LabelSelectorRequirement, whose values
# are [Str]. Since k145 a Str goes out as a JSON string, so a value 8080
# came back as "8080" -- the wrong JSON type for the schema's own field.
# A $ref to intstr.IntOrString in a swagger definition took the same path.
#
# Claims:
#   * int-or-string -- x-kubernetes-int-or-string, `type: string` with
#     `format: int-or-string`, or a $ref to intstr.IntOrString -- is
#     compatible with an IntOrStr field only: not with Str, and not with
#     [Str] for items, so those shapes get their own nested class, typed
#     IntOrStr / [IntOrStr], and 8080 stays a JSON number on the wire;
#   * where the shipped class does type the key IntOrStr
#     (Core::V1::TCPSocketAction.port), the shape is still reused, and an
#     integer schema still reuses it too;
#   * int-or-string never matches a Time field, as a scalar, as array
#     items or as map values; it does match a Quantity one, the form
#     controller-gen gives a resource.Quantity, so a CRD's ResourceList
#     still reuses VolumeResourceRequirements.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::AutoGen;
use IO::K8s::Api::Core::V1::ResourceRequirements;

my $true = JSON::MaybeXS::true();
my $IS   = '#/definitions/io.k8s.apimachinery.pkg.util.intstr.IntOrString';
my %defs = (
    'io.k8s.apimachinery.pkg.util.intstr.IntOrString' => { type => 'string', format => 'int-or-string' },
);

my $class = IO::K8s::AutoGen::get_or_generate('com.example.v1.K181Thing', {
    type       => 'object',
    properties => {
        header => {
            type       => 'object',
            properties => {
                name  => { type => 'string' },
                value => { 'x-kubernetes-int-or-string' => $true },
            },
        },
        formatHeader => {
            type       => 'object',
            properties => {
                name  => { type => 'string' },
                value => { type => 'string', format => 'int-or-string' },
            },
        },
        refHeader => {
            type       => 'object',
            properties => {
                name  => { type => 'string' },
                value => { '$ref' => $IS },
            },
        },
        requirement => {
            type       => 'object',
            properties => {
                key      => { type => 'string' },
                operator => { type => 'string' },
                values   => { type => 'array', items => { 'x-kubernetes-int-or-string' => $true } },
            },
        },
        probe => {
            type       => 'object',
            properties => {
                host => { type => 'string' },
                port => { 'x-kubernetes-int-or-string' => $true },
            },
        },
        intProbe => {
            type       => 'object',
            properties => {
                host => { type => 'string' },
                port => { type => 'integer' },
            },
        },
    },
}, { %defs }, 'IO::K8s::_AUTOGEN_k181');

my $info = $class->_k8s_attr_info;

subtest 'int-or-string does not reuse a Str or [Str] field' => sub {
    for my $field (qw( header formatHeader refHeader )) {
        my $nested = $info->{$field}{class};
        isnt($nested, 'IO::K8s::Api::Core::V1::HTTPHeader', "$field does not reuse HTTPHeader");
        ok($nested->_k8s_attr_info->{value}{is_int_or_string}, "$field value is typed IntOrStr");
    }
    my $req = $info->{requirement}{class};
    isnt($req, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement',
        'int-or-string items do not reuse LabelSelectorRequirement ([Str] values)');
    ok($req->_k8s_attr_info->{values}{is_array_of_int_or_string}, 'the values are typed [IntOrStr]');
};

subtest 'the wire keeps 8080 a number' => sub {
    my $obj = $class->new(
        header      => { name => 'port', value => 8080 },
        refHeader   => { name => 'port', value => 'http' },
        requirement => { key => 'port', operator => 'In', values => [8080, 'http'] },
    );
    is($obj->to_json,
        '{"header":{"name":"port","value":8080},"refHeader":{"name":"port","value":"http"},'
        . '"requirement":{"key":"port","operator":"In","values":[8080,"http"]}}',
        '->new: numbers stay numbers, strings stay strings');

    my $doc = '{"header":{"name":"port","value":8080},"requirement":{"key":"k","operator":"In","values":[1,"a"]}}';
    is($class->from_json($doc)->to_json, $doc, 'from_json -> to_json keeps the JSON types');
};

subtest 'an IntOrStr field is still reused, by int-or-string and integer alike' => sub {
    is($info->{probe}{class}, 'IO::K8s::Api::Core::V1::TCPSocketAction',
        '{host, port: int-or-string} reuses TCPSocketAction (port IntOrStr)');
    is($info->{intProbe}{class}, 'IO::K8s::Api::Core::V1::TCPSocketAction',
        '{host, port: integer} still reuses it too');
    is($class->new(probe => { host => 'h', port => 8080 })->to_json,
        '{"probe":{"host":"h","port":8080}}', 'and the reused field keeps 8080 a number');
};

my $QUANTITY_PATTERN = '^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$';

subtest 'element and value checks: IntOrStr or Quantity, never Str or Time' => sub {
    my $ctx = { defs => { %defs }, active => {} };
    my $fc  = sub { IO::K8s::AutoGen::_field_compatible($_[0], $_[1], $ctx) };
    my $int_or_string = { 'x-kubernetes-int-or-string' => $true };

    ok(!$fc->({ is_time => 1 }, $int_or_string), 'int-or-string is not compatible with a Time field');
    ok($fc->({ is_int_or_string => 1 }, $int_or_string), 'but is with an IntOrStr field');

    my $items = { type => 'array', items => $int_or_string };
    ok(!$fc->({ is_array_of_str => 1 },  $items), 'int-or-string items: not [Str]');
    ok(!$fc->({ is_array_of_time => 1 }, $items), 'not [Time]');
    ok($fc->({ is_array_of_int_or_string => 1 }, $items), 'but [IntOrStr]');

    my $ref_items = { type => 'array', items => { '$ref' => $IS } };
    ok(!$fc->({ is_array_of_str => 1 }, $ref_items), '$ref IntOrString items: not [Str]');
    ok($fc->({ is_array_of_int_or_string => 1 }, $ref_items), 'but [IntOrStr]');

    # controller-gen renders a resource.Quantity as int-or-string with the
    # quantity pattern, so a ResourceList is a map of those.
    my $resource_list = { type => 'object', additionalProperties => {
        anyOf => [ { type => 'integer' }, { type => 'string' } ],
        pattern => $QUANTITY_PATTERN, 'x-kubernetes-int-or-string' => $true,
    } };
    my $limits = IO::K8s::Api::Core::V1::ResourceRequirements->_k8s_attr_info->{limits};
    ok($fc->($limits, $resource_list), 'a controller-gen ResourceList still matches { Quantity => 1 }');
    ok(!$fc->({ is_hash_of_time => 1 }, $resource_list), 'but not { Time => 1 }');
};

subtest 'a controller-gen ResourceList still reuses VolumeResourceRequirements' => sub {
    my $quantity = {
        anyOf => [ { type => 'integer' }, { type => 'string' } ],
        pattern => $QUANTITY_PATTERN, 'x-kubernetes-int-or-string' => $true,
    };
    my $gen = IO::K8s::AutoGen::get_or_generate('com.example.v1.K181Claim', {
        type       => 'object',
        properties => {
            resources => {
                type       => 'object',
                properties => {
                    limits   => { type => 'object', additionalProperties => $quantity },
                    requests => { type => 'object', additionalProperties => $quantity },
                },
            },
        },
    }, {}, 'IO::K8s::_AUTOGEN_k181_claim');
    is($gen->_k8s_attr_info->{resources}{class}, 'IO::K8s::Api::Core::V1::VolumeResourceRequirements',
        'the {limits, requests} shape of a PVC template is reused as before');
};

done_testing;
