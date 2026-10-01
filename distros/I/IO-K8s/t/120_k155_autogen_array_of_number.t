#!/usr/bin/env perl
# k155: IO::K8s::AutoGen typed an array whose items are `type: number` as
# [Str]. k68 only fixed the scalar `type: number` case; the array branch of
# _schema_to_type_spec had no number arm and fell through to its [Str]
# default. Since k145 a [Str] element is serialized as a JSON string on
# purpose, so {"ratios":[1.5,2]} came back as {"ratios":["1.5","2"]} -- the
# wrong JSON type for a field the schema declares numeric, which the API
# server rejects.
#
# Claims:
#   * items: {type: number} becomes [Num] (is_array_of_num), and the wire
#     JSON keeps the elements as JSON numbers through ->new, inflate and
#     from_json -- checked on the JSON text, not only on Perl values;
#   * items: {type: integer} already was [Int] and stays so (the same gap
#     was checked for and is not there);
#   * a non-numeric element is refused, as the scalar Num field refuses it;
#   * the emitter renders the generated field back as [Num] and to_crd as
#     items: {type: number}, so add_crd -> to_crd -> add_crd keeps the type
#     (the k112 symmetry).
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

my $schema = {
    type       => 'object',
    properties => {
        ratios => { type => 'array', items => { type => 'number' } },
        counts => { type => 'array', items => { type => 'integer' } },
    },
};

my $class = IO::K8s::AutoGen::get_or_generate(
    'com.example.v1.K155Thing', $schema, {}, 'IO::K8s::_AUTOGEN_k155');

subtest 'items: {type: number} is typed [Num] in the registry' => sub {
    my $info = $class->_k8s_attr_info;
    ok($info->{ratios}{is_array_of_num}, 'ratios is an array of Num');
    ok(!$info->{ratios}{is_array_of_str}, 'ratios is not an array of Str');
    ok($info->{counts}{is_array_of_int}, 'counts stays an array of Int');
};

subtest 'wire JSON keeps number elements as numbers' => sub {
    my $obj = $class->new(ratios => [1.5, 2], counts => [1, 2]);
    is($obj->to_json, '{"counts":[1,2],"ratios":[1.5,2]}',
        '->new: ratios serialize as JSON numbers, not quoted strings');

    my $from_json = $class->from_json('{"ratios":[1.5,2]}');
    is($from_json->to_json, '{"ratios":[1.5,2]}', 'from_json -> to_json keeps the numbers');

    my $k8s = IO::K8s->new;
    my $via_struct = $k8s->struct_to_object("+$class", $json->decode('{"ratios":[1.5,2],"counts":[3]}'));
    is($via_struct->to_json, '{"counts":[3],"ratios":[1.5,2]}',
        'struct_to_object (the inflate path) -> to_json keeps the numbers');

    # A string that reads as a number is still a number field: numified on
    # the way out, exactly as the scalar Num field does it (k68).
    my $stringy = $class->new(ratios => ['0.25']);
    is($stringy->to_json, '{"ratios":[0.25]}', 'a numeric string element goes out as a JSON number');
};

subtest 'a non-numeric element is refused' => sub {
    throws_ok { $class->new(ratios => [1.5, 'fast']) }
        qr/ratios/, 'an element that is not a number fails the [Num] constraint';
};

# k112 symmetry: the emitter and to_crd read the same registry flag back.
my $crd = {
    apiVersion => 'apiextensions.k8s.io/v1',
    kind       => 'CustomResourceDefinition',
    metadata   => { name => 'dials.k155.example.com' },
    spec       => {
        group => 'k155.example.com',
        names => { kind => 'Dial', plural => 'dials', singular => 'dial', listKind => 'DialList' },
        scope => 'Namespaced',
        versions => [{
            name => 'v1', served => JSON::MaybeXS::true, storage => JSON::MaybeXS::true,
            schema => { openAPIV3Schema => {
                type       => 'object',
                properties => {
                    spec => {
                        type       => 'object',
                        properties => {
                            ratios => { type => 'array', items => { type => 'number' } },
                        },
                    },
                },
            } },
        }],
    },
};

subtest 'the emitter renders the generated field as [Num]' => sub {
    my $classes = IO::K8s::CRD->generate($crd, 'IO::K8s::_AUTOGEN_k155_crd');
    my $root = $classes->{'k155.example.com/v1'};
    my $files = IO::K8s::CRD::Emitter->new(base => 'TestK155::V1')->render($root);
    like($files->{'TestK155/V1/DialSpec.pm'}, qr/^k8s ratios => \[Num\];$/m,
        'rendered source declares ratios => [Num]');
};

subtest 'to_crd emits items: {type: number}, and add_crd reads it back as [Num]' => sub {
    my $classes = IO::K8s::CRD->generate($crd, 'IO::K8s::_AUTOGEN_k155_to_crd');
    my $root = $classes->{'k155.example.com/v1'};
    my $emitted = $root->to_crd;
    my $ratios = $emitted->TO_JSON->{spec}{versions}[0]{schema}{openAPIV3Schema}
        {properties}{spec}{properties}{ratios};
    is_deeply($ratios, { type => 'array', items => { type => 'number' } },
        'to_crd writes the array back with number items');

    my $reg = IO::K8s->new->add_crd($emitted);
    my $again = $reg->{Dial}{ $reg->{Dial}{storage} };
    my $spec_class = $again->_k8s_attr_info->{spec}{class};
    ok($spec_class->_k8s_attr_info->{ratios}{is_array_of_num},
        'add_crd(to_crd) types ratios as [Num] again');
};

done_testing;
