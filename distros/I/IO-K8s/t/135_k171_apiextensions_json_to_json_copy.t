#!/usr/bin/env perl
# k171: IO::K8s::ApiextensionsApiserver::...::V1::JSON->TO_JSON returned the
# stored value itself. A `default`, `example` or `enum` entry that is a hash
# or an array came out as the object's own container, so whoever
# post-processed $props->TO_JSON->{default} -- adding a key, pushing an
# element -- silently rewrote the object and every later serialization. The
# output side of k54/k169: FROM_STRUCT already copies on the way in, the
# role's TO_JSON copies an untyped container on the way out, and
# JSONSchemaPropsOrStringArray->TO_JSON already hands out a new array.
#
# Claims:
#   * TO_JSON hands out a hash or an array value copied one level: a key
#     added to or removed from the returned hash, an element pushed onto the
#     returned array, reaches neither the object nor its later wire output;
#   * the same holds for the struct a containing JSONSchemaProps returns
#     (default, example, and each enum entry);
#   * one level only: a container nested inside the value is still shared
#     (the documented k54 limit);
#   * a plain scalar, undef or a JSON boolean comes back as it is, and the
#     wire JSON is unchanged.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps;

my $k8s  = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1);

my $V1       = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::';
my $JSON_VAL = $V1.'JSON';
my $PROPS    = $V1.'JSONSchemaProps';

subtest 'a hash value: editing the TO_JSON output leaves the object alone' => sub {
    my $obj = $JSON_VAL->new(value => { replicas => 1, mode => 'auto' });
    my $out = $obj->TO_JSON;
    is_deeply($out, { replicas => 1, mode => 'auto' }, 'TO_JSON returns the value');
    $out->{extra} = 1;
    delete $out->{mode};
    is_deeply($obj->value, { replicas => 1, mode => 'auto' }, 'the object value is unchanged');
    is($json->encode($obj->TO_JSON), '{"mode":"auto","replicas":1}', 'and so is the wire JSON');
};

subtest 'an array value: editing the TO_JSON output leaves the object alone' => sub {
    my $obj = $JSON_VAL->new(value => [ 'a', 'b' ]);
    my $out = $obj->TO_JSON;
    push @$out, 'c';
    shift @$out;
    is_deeply($obj->value, [ 'a', 'b' ], 'the object value is unchanged');
    is($json->encode($obj->TO_JSON), '["a","b"]', 'and so is the wire JSON');
};

subtest 'through a JSONSchemaProps: default, example and enum entries' => sub {
    my $props = $k8s->struct_to_object("+$PROPS", {
        type    => 'object',
        default => { replicas => 1 },
        example => [ 1, 2 ],
        enum    => [ { tier => 'gold' } ],
    });
    my $before = $props->to_json;
    my $out = $props->TO_JSON;
    $out->{default}{replicas} = 99;
    push @{ $out->{example} }, 3;
    $out->{enum}[0]{tier} = 'lead';
    is($props->to_json, $before, 'the wire JSON after editing the returned struct is unchanged');
    is_deeply($props->default->value, { replicas => 1 }, 'default unchanged');
    is_deeply($props->example->value, [ 1, 2 ], 'example unchanged');
    is_deeply($props->enum->[0]->value, { tier => 'gold' }, 'enum entry unchanged');
};

subtest 'one level only: a nested container is still shared' => sub {
    my $obj = $JSON_VAL->new(value => { image => { tag => 'v1' } });
    $obj->TO_JSON->{image}{tag} = 'v2';
    is($obj->value->{image}{tag}, 'v2', 'the inner hash is the same one (k54 depth)');
};

subtest 'a scalar, undef or a JSON boolean comes back as it is' => sub {
    is($JSON_VAL->new(value => 'nginx')->TO_JSON, 'nginx', 'a plain string');
    is($JSON_VAL->new(value => 3)->TO_JSON, 3, 'a number');
    is($JSON_VAL->new(value => undef)->TO_JSON, undef, 'undef');
    my $true = JSON::MaybeXS::true();
    ok($JSON_VAL->new(value => $true)->TO_JSON == $true, 'a JSON boolean is the same object');
    is($json->encode($JSON_VAL->new(value => $true)->TO_JSON), 'true', 'and encodes as true');
};

done_testing;
