#!/usr/bin/env perl
# k167: IO::K8s::AutoGen typed an array whose items carry
# `x-kubernetes-int-or-string: true` (or the swagger v2 `format:
# int-or-string`) or `type: string, format: date-time` as [Str]. The scalar
# forms were already IntOrStr and Time; the array branch of
# _schema_to_type_spec had no arm for either and fell through to its [Str]
# default. Since k145 a [Str] element goes out as a JSON string, so
# {"ports":[8080,"http"]} came back as {"ports":["8080","http"]} -- the wrong
# JSON type for an int-or-string element. TO_JSON also had no branch for
# [IntOrStr], [Quantity] and [Time]: they fell through to the generic array
# copy, so a [IntOrStr] element did not get the scalar IntOrStr rule and a
# numeric [Quantity] element went out as a JSON number.
#
# Claims:
#   * int-or-string items become [IntOrStr] (is_array_of_int_or_string),
#     date-time items [Time] (is_array_of_time) -- the array form of the
#     scalar case, for the extension and the format alike;
#   * the wire JSON keeps an int-or-string element's number a number and its
#     string a string, through ->new, from_json and the inflate path, and an
#     all-digit string follows the scalar IntOrStr rule (goes out as a
#     number) -- checked on the JSON text, not only on Perl values;
#   * a [Quantity] and a [Time] element go out as JSON strings, the wire form
#     Kubernetes gives both; undef and reference elements are left alone,
#     and the struct TO_JSON returns is a copy that does not alias the object;
#   * a [Time] array default whose elements a [Time] cannot hold is dropped
#     like any other malformed default, not fatal to the class generation
#     (since k178 a generated [Time] element takes any string, as the
#     scalar Time of a generated class does, so that is a reference);
#   * a map whose additionalProperties is int-or-string or date-time has no
#     such gap: it stays the opaque { Str => 1 } map, which copies values
#     unchanged;
#   * the emitter renders the generated fields back as [IntOrStr] / [Time],
#     to_crd writes the matching items schema, and add_crd reads it back as
#     the same type (the k112 symmetry).
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::AutoGen;
use IO::K8s::CRD;
use IO::K8s::CRD::Emitter;

my $json = JSON::MaybeXS->new(canonical => 1, utf8 => 1);
my $true = JSON::MaybeXS::true();

my $schema = {
    type       => 'object',
    properties => {
        ports    => { type => 'array', items => { 'x-kubernetes-int-or-string' => $true } },
        surges   => { type => 'array', items => { type => 'string', format => 'int-or-string' } },
        stamps   => { type => 'array', items => { type => 'string', format => 'date-time' } },
        port     => { 'x-kubernetes-int-or-string' => $true },
        portMap  => { type => 'object', additionalProperties => { 'x-kubernetes-int-or-string' => $true } },
        stampMap => { type => 'object', additionalProperties => { type => 'string', format => 'date-time' } },
        # a format on items without `type: string` is not a date-time, the
        # same as for a scalar property
        loose    => { type => 'array', items => { format => 'date-time' } },
    },
};

my $class = IO::K8s::AutoGen::get_or_generate(
    'com.example.v1.K167Thing', $schema, {}, 'IO::K8s::_AUTOGEN_k167');

subtest 'int-or-string and date-time items are typed like their scalar form' => sub {
    my $info = $class->_k8s_attr_info;
    ok($info->{ports}{is_array_of_int_or_string}, 'x-kubernetes-int-or-string items: [IntOrStr]');
    ok($info->{surges}{is_array_of_int_or_string}, 'format: int-or-string items: [IntOrStr]');
    ok($info->{stamps}{is_array_of_time}, 'format: date-time items: [Time]');
    ok(!$info->{$_}{is_array_of_str}, "$_ is not an array of Str") for qw( ports surges stamps );
    ok($info->{port}{is_int_or_string}, 'the scalar int-or-string property stays IntOrStr');
    ok($info->{loose}{is_array_of_str}, 'a format without type: string stays [Str], as for a scalar');
};

subtest 'wire JSON keeps int-or-string elements as the JSON type they were' => sub {
    my $obj = $class->new(ports => [8080, 'http'], surges => ['25%', 1]);
    is($obj->to_json, '{"ports":[8080,"http"],"surges":["25%",1]}',
        '->new: numbers stay numbers, strings stay strings');

    my $from_json = $class->from_json('{"ports":[8080,"http"]}');
    is($from_json->to_json, '{"ports":[8080,"http"]}', 'from_json -> to_json keeps both types');

    my $k8s = IO::K8s->new;
    my $via_struct = $k8s->struct_to_object("+$class", $json->decode('{"ports":[8080,"http"],"surges":["25%"]}'));
    is($via_struct->to_json, '{"ports":[8080,"http"],"surges":["25%"]}',
        'struct_to_object (the inflate path) -> to_json keeps both types');

    # The element rule is the scalar IntOrStr rule, applied per element.
    my $digits = $class->new(ports => ['7', '-3', '7a'], port => '7');
    is($digits->to_json, '{"port":7,"ports":[7,-3,"7a"]}',
        'an all-digit string element goes out as a number, exactly like the scalar IntOrStr field');
};

subtest 'wire JSON keeps date-time elements as strings' => sub {
    my $obj = $class->new(stamps => ['2026-09-27T12:00:00Z']);
    is($obj->to_json, '{"stamps":["2026-09-27T12:00:00Z"]}', '->new: a [Time] element is a JSON string');
    is($class->from_json('{"stamps":["2026-09-27T12:00:00Z"]}')->to_json,
        '{"stamps":["2026-09-27T12:00:00Z"]}', 'from_json -> to_json');
    # k178: a generated [Time] element follows the scalar rule (any string);
    # t/144 has the one-rule claim. It still refuses what no Time can be.
    throws_ok { $class->new(stamps => [ {} ]) }
        qr/stamps/, 'a reference element fails the [Time] constraint';
};

subtest 'a [Time] default the elements cannot hold is dropped, not fatal' => sub {
    my $gen;
    lives_ok {
        $gen = IO::K8s::AutoGen::get_or_generate('com.example.v1.K167Defaults', {
            type       => 'object',
            properties => {
                bad  => { type => 'array', items => { type => 'string', format => 'date-time' },
                          default => [ {} ] },
                good => { type => 'array', items => { type => 'string', format => 'date-time' },
                          default => ['2026-09-27T12:00:00Z'] },
                flex => { type => 'array', items => { 'x-kubernetes-int-or-string' => $true },
                          default => [1, '25%'] },
            },
        }, {}, 'IO::K8s::_AUTOGEN_k167_defaults');
    } 'a date-time array default no [Time] can hold does not fail class generation';
    my $info = $gen->_k8s_attr_info;
    ok(!exists $info->{bad}{options}{default}, 'the malformed default is dropped');
    is_deeply($info->{good}{options}{default}, ['2026-09-27T12:00:00Z'], 'a valid one is kept');
    is_deeply($info->{flex}{options}{default}, [1, '25%'], 'an int-or-string array default is kept');
};

subtest 'maps of int-or-string / date-time values have no such gap' => sub {
    my $info = $class->_k8s_attr_info;
    # k191 replaces the first two claims: these maps are no longer the
    # opaque { Str => 1 } (which became the string map) but typed maps,
    # HashRef[IntOrStr] and HashRef[Time]. The wire claim below is kept --
    # an int-or-string value 8080 stays a number, now by the typed map's
    # per-value rule instead of an untouched copy.
    ok($info->{portMap}{is_hash_of_int_or_string}, 'int-or-string additionalProperties: HashRef[IntOrStr]');
    ok($info->{stampMap}{is_hash_of_time}, 'date-time additionalProperties: HashRef[Time]');
    ok(!$info->{$_}{is_hash_of_str}, "$_ is not a string map") for qw( portMap stampMap );
    my $obj = $class->new(portMap => { a => 8080, b => 'http' }, stampMap => { at => '2026-09-27T12:00:00Z' });
    is($obj->to_json, '{"portMap":{"a":8080,"b":"http"},"stampMap":{"at":"2026-09-27T12:00:00Z"}}',
        'map values keep their wire type: an int-or-string number is not stringified');
};

# The TO_JSON branches themselves, on hand-declared classes (DSL forms the
# shipped classes use -- DeviceCapacity.validValues is [Quantity]).
{
    package TestK167::Scalars;
    use IO::K8s::Resource;
    k8s flexes     => [IntOrStr];
    k8s quantities => [Quantity];
    k8s times      => [Time];
    k8s flex       => IntOrStr;
}

subtest 'TO_JSON: [IntOrStr], [Quantity] and [Time] each get their own rule' => sub {
    my $obj = TestK167::Scalars->new(
        flexes     => [1, '20%', '3'],
        quantities => [1, '500m', 2.5],
        times      => ['2024-01-01T00:00:00Z'],
        flex       => '3',
    );
    is($obj->to_json,
        '{"flex":3,"flexes":[1,"20%",3],"quantities":["1","500m","2.5"],"times":["2024-01-01T00:00:00Z"]}',
        'IntOrStr per element as the scalar rule, Quantity and Time elements as JSON strings');

    # Elements the constructor never saw (a push onto the accessor's
    # arrayref) may be undef or a ref; they go out as they are, the way the
    # [Str] and [Num] branches leave them.
    push @{ $obj->flexes }, undef;
    push @{ $obj->quantities }, undef, [ 'x' ];
    my $data = $obj->TO_JSON;
    is($data->{flexes}[-1], undef, 'an undef [IntOrStr] element is left alone');
    is($data->{quantities}[-2], undef, 'an undef [Quantity] element is left alone');
    is_deeply($data->{quantities}[-1], ['x'], 'a reference [Quantity] element is left alone');

    # One-level copy (k54): the struct must not alias the object.
    push @{ $data->{$_} }, 'extra' for qw( flexes quantities times );
    is(scalar @{ $obj->flexes },     4, 'pushing onto the TO_JSON [IntOrStr] array leaves the object alone');
    is(scalar @{ $obj->quantities }, 5, 'pushing onto the TO_JSON [Quantity] array leaves the object alone');
    is(scalar @{ $obj->times },      1, 'pushing onto the TO_JSON [Time] array leaves the object alone');
};

# k112 symmetry: the emitter and to_crd read the same registry flags back.
my $crd = {
    apiVersion => 'apiextensions.k8s.io/v1',
    kind       => 'CustomResourceDefinition',
    metadata   => { name => 'gates.k167.example.com' },
    spec       => {
        group => 'k167.example.com',
        names => { kind => 'Gate', plural => 'gates', singular => 'gate', listKind => 'GateList' },
        scope => 'Namespaced',
        versions => [{
            name => 'v1', served => $true, storage => $true,
            schema => { openAPIV3Schema => {
                type       => 'object',
                properties => {
                    spec => {
                        type       => 'object',
                        properties => {
                            ports  => { type => 'array', items => { 'x-kubernetes-int-or-string' => $true } },
                            stamps => { type => 'array', items => { type => 'string', format => 'date-time' } },
                        },
                    },
                },
            } },
        }],
    },
};

subtest 'the emitter renders the generated fields as [IntOrStr] and [Time]' => sub {
    my $classes = IO::K8s::CRD->generate($crd, 'IO::K8s::_AUTOGEN_k167_crd');
    my $root = $classes->{'k167.example.com/v1'};
    my $files = IO::K8s::CRD::Emitter->new(base => 'TestK167::V1')->render($root);
    my $src = $files->{'TestK167/V1/GateSpec.pm'};
    like($src, qr/^k8s ports\s+=> \[IntOrStr\];$/m, 'rendered source declares ports => [IntOrStr]');
    like($src, qr/^k8s stamps\s+=> \[Time\];$/m,    'rendered source declares stamps => [Time]');
};

subtest 'to_crd writes the items back, and add_crd reads them as the same type' => sub {
    my $classes = IO::K8s::CRD->generate($crd, 'IO::K8s::_AUTOGEN_k167_to_crd');
    my $root = $classes->{'k167.example.com/v1'};
    my $props = $root->to_crd->TO_JSON->{spec}{versions}[0]{schema}{openAPIV3Schema}
        {properties}{spec}{properties};
    is_deeply($props->{ports}, { type => 'array', items => { 'x-kubernetes-int-or-string' => $true } },
        'to_crd writes ports with int-or-string items');
    is_deeply($props->{stamps}, { type => 'array', items => { type => 'string', format => 'date-time' } },
        'to_crd writes stamps with date-time items');

    my $reg = IO::K8s->new->add_crd($root->to_crd);
    my $again = $reg->{Gate}{ $reg->{Gate}{storage} };
    my $spec_info = $again->_k8s_attr_info->{spec}{class}->_k8s_attr_info;
    ok($spec_info->{ports}{is_array_of_int_or_string}, 'add_crd(to_crd) types ports as [IntOrStr] again');
    ok($spec_info->{stamps}{is_array_of_time}, 'add_crd(to_crd) types stamps as [Time] again');
};

done_testing;
