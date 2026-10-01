#!/usr/bin/env perl
# k145: Str-typed fields (and [Str] array elements) must serialize as JSON
# strings on the wire. TO_JSON's Bool/Int/Num/IntOrStr normalization in
# lib/IO/K8s/Role/Resource.pm (~292-359) never touches is_str / is_array_of_str
# values, so a numeric Perl scalar assigned to a Str field falls through to
# the generic `$data{$key} = $value` branch at the end of TO_JSON, and
# JSON::MaybeXS encodes an un-stringified Perl integer/float unquoted --
# Kubernetes expects a JSON string there. Confirmed repro:
# IO::K8s::Api::Core::V1::EnvVar->new(name => 'PORT', value => 8080)->to_json
# is '{"name":"PORT","value":8080}'; "value" is declared Str.
#
# Approved fix (NOT implemented by this file): stringify a numeric Perl
# scalar for is_str fields and is_array_of_str elements at TO_JSON time.
#
# Wire types are checked over the produced JSON text (or a canonical
# re-encode of TO_JSON/object_to_struct) -- a Perl-level comparison can't
# tell 8080 from "8080", since Perl treats them as the same value.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use lib 'lib';

use IO::K8s;
use IO::K8s::Api::Core::V1::Pod;
use IO::K8s::Api::Core::V1::EnvVar;
use IO::K8s::Api::Core::V1::Container;
use IO::K8s::Api::Core::V1::ContainerPort;
use IO::K8s::Api::Core::V1::ServicePort;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;
use IO::K8s::Api::Autoscaling::V2::MetricTarget;
use JSON::MaybeXS;

my $k8s = IO::K8s->new;

# ----------------------------------------------------------------------------
# Test-local fixture classes, declared up front (t/06, t/46, t/144 style)
# rather than inside a subtest closure.
# ----------------------------------------------------------------------------

{
    package Test::K145::NumField;
    use IO::K8s::Resource;
    k8s value => Num;
}

{
    package Test::K145::OpaqueSpec;
    use IO::K8s::APIObject
        api_version     => 'k145.example.com/v1',
        resource_plural => 'opaquespecs';
    # k191: this fixture used to be `{ Str => 1 }`, which was the opaque map.
    # Since k191 { Str => 1 } is a real string map (numbers become JSON
    # strings), so the fixture moved to Opaque to keep the claim below alive:
    # the opaque map is left untouched. Only the declaration changed, not
    # what the GUARD asserts.
    k8s spec => Opaque;
}

# ============================================================================
# RED: Str-typed scalar fields and [Str] array elements must quote a numeric
# Perl value on the wire.
# ============================================================================

# Claim: EnvVar.value is declared Str; a numeric Perl scalar must still
# serialize as a JSON string, not a bare number.
subtest 'EnvVar value: numeric Perl scalar serializes as a JSON string' => sub {
    my $env = IO::K8s::Api::Core::V1::EnvVar->new(name => 'PORT', value => 8080);
    like($env->to_json, qr/"value":"8080"/, 'value is quoted on the wire');
    unlike($env->to_json, qr/"value":8080(?:,|\})/, 'value is not a bare JSON number');
};

# Claim: a falsy-but-meaningful numeric value (0) must still be quoted --
# the edge case a truthiness-based fix would get wrong, and TO_JSON already
# uses `defined`, not truthiness, to decide whether to emit the field at all.
subtest 'EnvVar value: 0 still serializes as a quoted JSON string' => sub {
    my $env = IO::K8s::Api::Core::V1::EnvVar->new(name => 'ZERO', value => 0);
    like($env->to_json, qr/"value":"0"/, 'value 0 is quoted, not a bare 0');
};

# Claim: the same field embedded inside a Pod built via IO::K8s->new_object
# (the common consumer path) still quotes the numeric value.
subtest 'embedded via new_object: Container env value stays a JSON string' => sub {
    my $obj = $k8s->new_object('Pod',
        metadata => { name => 'p' },
        spec     => { containers => [
            { name => 'app', image => 'nginx', env => [ { name => 'PORT', value => 8080 } ] },
        ] },
    );
    like($obj->to_json, qr/"value":"8080"/, 'env value is quoted via new_object');
};

# Claim: the same field built via direct ->new construction (the k8s DSL's
# own object-field coercers, bypassing IO::K8s's factory entirely) must also
# quote it -- the bug lives in TO_JSON, which every construction path shares.
subtest 'embedded via direct construction: Container env value stays a JSON string' => sub {
    my $pod = IO::K8s::Api::Core::V1::Pod->new(
        metadata => { name => 'p' },
        spec     => { containers => [
            { name => 'app', image => 'nginx', env => [ { name => 'PORT', value => 8080 } ] },
        ] },
    );
    like($pod->to_json, qr/"value":"8080"/, 'env value is quoted via direct ->new');
};

# Claim: object_to_struct (the struct-returning sibling to_json builds on)
# must agree once re-encoded through a plain canonical JSON encoder -- the
# bug is in TO_JSON, not in to_json's own encoder configuration.
subtest 'object_to_struct + canonical re-encode shows the same quoted string' => sub {
    my $env = IO::K8s::Api::Core::V1::EnvVar->new(name => 'PORT', value => 8080);
    my $struct = $k8s->object_to_struct($env);
    my $reencoded = JSON::MaybeXS->new(canonical => 1)->encode($struct);
    like($reencoded, qr/"value":"8080"/, 'object_to_struct + re-encode also quotes value');
};

# Claim: an [Str] array field with a numeric element must quote that element
# too -- the same is_str normalization has to reach array-of-string elements,
# leaving genuine string elements untouched.
subtest "Container args ([Str]): a numeric element serializes as a JSON string" => sub {
    my $c = IO::K8s::Api::Core::V1::Container->new(name => 'app', args => [ 1, 'x' ]);
    like($c->to_json, qr/"args":\["1","x"\]/, 'numeric array element is quoted, string element unaffected');
};

# Claim: command shares the same [Str] declaration and must behave the same way.
subtest "Container command ([Str]): a numeric element serializes as a JSON string" => sub {
    my $c = IO::K8s::Api::Core::V1::Container->new(name => 'app', command => [ 2, 'sh' ]);
    like($c->to_json, qr/"command":\["2","sh"\]/, 'numeric array element is quoted');
};

# ============================================================================
# GUARDS: wire types the fix must not touch stay exactly as they are today.
# ============================================================================

# Claim: Int-typed fields keep serializing as an unquoted JSON number.
subtest 'GUARD: Int field (containerPort) stays an unquoted JSON number' => sub {
    my $p = IO::K8s::Api::Core::V1::ContainerPort->new(containerPort => 8080);
    like($p->to_json, qr/"containerPort":8080(?:,|\})/, 'containerPort is unquoted');
};

# Claim: IntOrStr given a numeric value keeps serializing as an unquoted number.
subtest 'GUARD: IntOrStr field (targetPort) numeric input stays a JSON number' => sub {
    my $sp = IO::K8s::Api::Core::V1::ServicePort->new(port => 80, targetPort => 8080);
    like($sp->to_json, qr/"targetPort":8080(?:,|\})/, 'targetPort is unquoted when given a number');
};

# Claim: Bool fields keep serializing as real JSON booleans.
subtest 'GUARD: Bool field (stdin) stays a real JSON boolean' => sub {
    my $c = IO::K8s::Api::Core::V1::Container->new(name => 'app', stdin => 1);
    like($c->to_json, qr/"stdin":true/, 'stdin serializes as JSON true, not "1" or 1');
};

# Claim: Num fields keep serializing as an unquoted JSON number. No shipped
# Core V1 class has a scalar Num field, so a minimal local class exercises
# the same TO_JSON is_num branch (declared above, Test::K145::NumField).
subtest 'GUARD: Num field stays an unquoted JSON number' => sub {
    my $o = Test::K145::NumField->new(value => 3.5);
    like($o->to_json, qr/"value":3\.5(?:,|\})/, 'Num field is unquoted');
};

# Claim: an opaque hash field (Opaque; before k191 spelled { Str => 1 }) is
# deliberately untyped -- its nested numbers and booleans must survive
# unchanged, never be stringified (declared above, Test::K145::OpaqueSpec).
subtest 'GUARD: opaque hash field (Opaque) leaves nested numbers/bools alone' => sub {
    my $o = Test::K145::OpaqueSpec->new(
        metadata => { name => 'x' },
        spec     => { replicas => 3, enabled => JSON::MaybeXS::true, nested => { n => 1 } },
    );
    my $json = $o->to_json;
    like($json, qr/"replicas":3(?:,|\})/, 'opaque hash: nested integer stays unquoted');
    like($json, qr/"enabled":true/, 'opaque hash: nested boolean stays a real JSON boolean');
    like($json, qr/"n":1(?:,|\})/, 'opaque hash: deeply nested integer stays unquoted');
};

# Claim: an undeclared constructor key (not in the k8s attribute registry)
# rides the _unknown_fields bag verbatim and must not be swept into the Str
# fix, since the bag has no type information to stringify against.
subtest 'GUARD: unknown/undeclared field with a numeric value stays a number' => sub {
    my $env = IO::K8s::Api::Core::V1::EnvVar->new(name => 'X', bogusField => 42);
    like($env->to_json, qr/"bogusField":42(?:,|\})/, 'undeclared field is not stringified');
};

# Claim: Quantity/Time scalar fields are out of scope for k145 -- this pins
# their CURRENT behaviour as a literal fact, not a specification of what they
# "should" do, so it stays green whichever way that currently happens to
# work, before and after the fix.
subtest 'GUARD (literal capture): Quantity/Time fields are unaffected by this fix' => sub {
    my $target_str = IO::K8s::Api::Autoscaling::V2::MetricTarget->new(type => 'Value', value => '100m');
    like($target_str->to_json, qr/"value":"100m"/, 'Quantity given as a string stays a quoted string');

    # k145 left is_quantity alone and this guard pinned the bare number it
    # still wrote then; k180 made every Quantity a JSON string (t/145).
    my $target_num = IO::K8s::Api::Autoscaling::V2::MetricTarget->new(type => 'Value', value => 100);
    like($target_num->to_json, qr/"value":"100"(?:,|\})/,
        'Quantity given as a bare Perl number serializes as a quoted string since k180');

    my $meta = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(
        creationTimestamp => '2024-01-01T00:00:00Z',
    );
    like($meta->to_json, qr/"creationTimestamp":"2024-01-01T00:00:00Z"/,
        'Time field stays a quoted string (its format regex requires a string already)');
};

done_testing;
