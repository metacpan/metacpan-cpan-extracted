#!/usr/bin/env perl
# k169: IO::K8s::ApiextensionsApiserver::...::V1::JSON->FROM_STRUCT stored
# the value it was handed by reference. A `default`, `example` or `enum`
# entry that is a hash or an array was the caller's own container, so a
# later edit to the source structure -- the CRD manifest a schema was
# inflated from -- silently rewrote the object and every later
# serialization. Since k152 AutoGen types a $ref to v1.JSON as this class,
# so the same held for generated classes.
#
# Approved contract, the k54 rule for arrays and hashes of scalars:
#   * FROM_STRUCT copies a container value one level -- a key added to or
#     removed from the source hash, an element pushed onto the source
#     array, does not reach the object;
#   * one level only: a container nested inside the value still shares
#     its inner references with the source (the documented k54 limit);
#   * a plain scalar, undef or a JSON boolean is kept as given;
#   * the wire output is unchanged.
# The sibling unions JSONSchemaPropsOr{Array,Bool,StringArray} already
# build their own containers; their GUARD pins that.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS ();
use lib 'lib';

use IO::K8s;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrArray;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrStringArray;

my $k8s = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1);

my $V1        = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::';
my $JSON_VAL  = $V1.'JSON';
my $PROPS     = $V1.'JSONSchemaProps';
my $OR_ARRAY  = $V1.'JSONSchemaPropsOrArray';
my $OR_BOOL   = $V1.'JSONSchemaPropsOrBool';
my $OR_STRARR = $V1.'JSONSchemaPropsOrStringArray';

# ===========================================================================
# FROM_STRUCT copies one level
# ===========================================================================

# Claim: a hash value is the object's own -- adding or removing a source
# key after inflation changes neither the object nor its wire output.
subtest 'a hash value does not alias the source' => sub {
    my $src = { replicas => 1, mode => 'auto' };
    my $obj = $JSON_VAL->FROM_STRUCT($src, $k8s);
    $src->{extra} = 1;
    delete $src->{mode};
    is_deeply($obj->value, { replicas => 1, mode => 'auto' }, 'value unchanged');
    is($json->encode($obj->TO_JSON), '{"mode":"auto","replicas":1}', 'wire unchanged');
};

# Claim: an array value is the object's own -- pushing onto or emptying the
# source array afterwards does not reach the object.
subtest 'an array value does not alias the source' => sub {
    my $src = [ 'a', 'b' ];
    my $obj = $JSON_VAL->FROM_STRUCT($src, $k8s);
    push @$src, 'c';
    is_deeply($obj->value, [ 'a', 'b' ], 'value unchanged after push');
    @$src = ();
    is($json->encode($obj->TO_JSON), '["a","b"]', 'wire unchanged after emptying the source');
};

# Claim: the copy is one level deep, not deeper -- the k54 limit. A
# container inside the value still shares its references with the source.
# Pinned so a change of depth shows up here instead of silently.
subtest 'the documented depth limit: one level, not deeper' => sub {
    my $src = { outer => { inner => 1 } };
    my $obj = $JSON_VAL->FROM_STRUCT($src, $k8s);
    $src->{top} = 1;
    ok(!exists $obj->value->{top}, 'depth 1 copied');
    $src->{outer}{inner} = 'MUTATED-DEPTH-2';
    is($obj->value->{outer}{inner}, 'MUTATED-DEPTH-2', 'depth 2 still shared -- documented limit, not a bug');
};

# Claim: a scalar, undef and a JSON boolean are kept exactly as given and
# go out on the wire as before.
subtest 'scalars, undef and booleans are kept as given' => sub {
    my $true = JSON::MaybeXS::true();
    is($JSON_VAL->FROM_STRUCT('nginx', $k8s)->value, 'nginx', 'string');
    is($JSON_VAL->FROM_STRUCT(3, $k8s)->value, 3, 'number');
    ok(!defined $JSON_VAL->FROM_STRUCT(undef, $k8s)->value, 'undef');
    my $bool = $JSON_VAL->FROM_STRUCT($true, $k8s);
    is($bool->value, $true, 'the same JSON boolean');
    is($json->encode($bool->TO_JSON), 'true', 'boolean on the wire');
};

# ===========================================================================
# Through the classes that hold it
# ===========================================================================

# Claim: default, example and each enum entry of an inflated JSONSchemaProps
# are the object's own -- editing the source schema afterwards leaves the
# object and its wire output as they were.
subtest 'JSONSchemaProps default / example / enum' => sub {
    my $src = {
        type    => 'object',
        default => { mode => 'auto' },
        example => [ 1, 2 ],
        enum    => [ { mode => 'auto' }, 'manual' ],
    };
    my $props  = $k8s->struct_to_object('+'.$PROPS, $src);
    my $before = $json->encode($props->TO_JSON);

    $src->{default}{mode} = 'MUTATED';
    push @{ $src->{example} }, 3;
    $src->{enum}[0]{extra} = 1;

    is_deeply($props->default->value, { mode => 'auto' }, 'default unchanged');
    is_deeply($props->example->value, [ 1, 2 ], 'example unchanged');
    is_deeply($props->enum->[0]->value, { mode => 'auto' }, 'enum entry unchanged');
    is($json->encode($props->TO_JSON), $before, 'wire unchanged');
};

# Claim: the real-world path -- a whole CustomResourceDefinition manifest
# inflated, then the manifest edited -- leaves the object and its JSON as
# they were.
subtest 'an inflated CustomResourceDefinition does not alias its manifest' => sub {
    my $spec_schema = {
        type       => 'object',
        properties => {
            mode  => { type => 'object', default => { level => 'low' } },
            ports => { type => 'array', items => { type => 'integer' }, default => [ 80 ] },
        },
    };
    my $manifest = {
        apiVersion => 'apiextensions.k8s.io/v1',
        kind       => 'CustomResourceDefinition',
        metadata   => { name => 'knobs.opts.example.com' },
        spec       => {
            group    => 'opts.example.com',
            scope    => 'Namespaced',
            names    => { kind => 'Knob', plural => 'knobs' },
            versions => [ {
                name    => 'v1',
                served  => JSON::MaybeXS::true(),
                storage => JSON::MaybeXS::true(),
                schema  => { openAPIV3Schema => {
                    type       => 'object',
                    properties => { spec => $spec_schema },
                } },
            } ],
        },
    };
    my $crd    = $k8s->inflate($manifest);
    my $before = $crd->to_json;

    $spec_schema->{properties}{mode}{default}{level} = 'MUTATED';
    push @{ $spec_schema->{properties}{ports}{default} }, 443;

    is($crd->to_json, $before, 'to_json unchanged after editing the manifest');
};

# ===========================================================================
# GUARD: the sibling unions build their own containers
# ===========================================================================

# Claim: JSONSchemaPropsOrArray, -OrBool and -OrStringArray never held the
# caller's container -- editing the source after FROM_STRUCT does not reach
# the wire output. No change there, pinned alongside k169.
subtest 'GUARD: JSONSchemaPropsOr{Array,Bool,StringArray} do not alias the source' => sub {
    my %cases = (
        "$OR_ARRAY, array arm"      => [ $OR_ARRAY,  [ { type => 'string' } ],         sub { push @{ $_[0] }, { type => 'integer' } } ],
        "$OR_ARRAY, schema arm"     => [ $OR_ARRAY,  { type => 'object', required => [ 'a' ] },
                                         sub { push @{ $_[0]{required} }, 'b'; $_[0]{type} = 'MUTATED' } ],
        "$OR_BOOL, schema arm"      => [ $OR_BOOL,   { type => 'object', required => [ 'a' ] },
                                         sub { push @{ $_[0]{required} }, 'b' } ],
        "$OR_STRARR, array arm"     => [ $OR_STRARR, [ 'a', 'b' ],                      sub { push @{ $_[0] }, 'c' } ],
        "$OR_STRARR, schema arm"    => [ $OR_STRARR, { type => 'object', required => [ 'a' ] },
                                         sub { push @{ $_[0]{required} }, 'b' } ],
    );
    for my $label (sort keys %cases) {
        my ($class, $src, $mutate) = @{ $cases{$label} };
        my $obj    = $class->FROM_STRUCT($src, $k8s);
        my $before = $json->encode($obj->TO_JSON);
        $mutate->($src);
        is($json->encode($obj->TO_JSON), $before, $label);
    }
};

done_testing;
