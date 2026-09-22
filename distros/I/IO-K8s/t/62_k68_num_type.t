#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::K8s;
use IO::K8s::AutoGen;

# k68: AutoGen mapped OpenAPI type: number to Str, so a JSON number in a
# generated class round-tripped as a quoted string ({"cpu":1.5} came back
# {"cpu":"1.5"}), which the API server rejects for a numeric field. The DSL had
# no numeric scalar type to map onto -- Int int-casts, but there was no Num.
# This adds a Num form (is_num + a TO_JSON numify branch mirroring is_int) and
# points AutoGen's number mapping at it.

# --- The DSL form directly (Type::Tiny object) ---
{
    package Test::Karr68::Thing;
    use IO::K8s::Resource;
    k8s ratio => Num;
}

my $hand = Test::Karr68::Thing->new(ratio => 2.5);
is($hand->TO_JSON->{ratio}, 2.5, 'Num field TO_JSON keeps the numeric value');
like($hand->to_json, qr/"ratio":2\.5/, 'Num field serializes UNQUOTED');
unlike($hand->to_json, qr/"ratio":"2\.5"/, 'Num field is not a quoted string');

# A whole-number value stays a JSON number, not a string.
my $whole = Test::Karr68::Thing->new(ratio => 3);
like($whole->to_json, qr/"ratio":3\b/, 'integral Num value is still an unquoted number');

# --- AutoGen maps type: number onto Num ---
IO::K8s::AutoGen::clear_cache();
my $schema = { type => 'object', properties => {
    cpu => { type => 'number' },
} };
my $class = IO::K8s::AutoGen::get_or_generate(
    'com.example.v1.NumThing', $schema, {}, 'IO::K8s::_AUTOGEN_karr68');

my $obj = $class->new(cpu => 1.5);
is($obj->TO_JSON->{cpu}, 1.5, 'AutoGen number field round-trips as a number');
like($obj->to_json, qr/"cpu":1\.5/, 'AutoGen number field serializes unquoted');
unlike($obj->to_json, qr/"cpu":"1\.5"/, 'AutoGen number field is not quoted');

# k71 (P6): the above only exercises Num via direct construction
# (->new) + TO_JSON. This rounds it through the LOAD paths -- FROM_HASH and
# from_json -- so a JSON number decoded off the wire stays numeric end to
# end, not just when the value is handed in already as a Perl number.
subtest 'is_num round-trips through the load paths FROM_HASH and from_json (k71)' => sub {
    my $via_hash = Test::Karr68::Thing->FROM_HASH({ ratio => 1.5 });
    is($via_hash->ratio, 1.5, 'FROM_HASH keeps the numeric value');
    like($via_hash->to_json, qr/"ratio":1\.5/, 'to_json after FROM_HASH is unquoted');
    unlike($via_hash->to_json, qr/"ratio":"1\.5"/, 'to_json after FROM_HASH is not a quoted string');

    my $via_json = Test::Karr68::Thing->from_json('{"ratio":1.5}');
    is($via_json->ratio, 1.5, 'from_json keeps the numeric value');
    like($via_json->to_json, qr/"ratio":1\.5/, 'to_json after from_json is unquoted');
    unlike($via_json->to_json, qr/"ratio":"1\.5"/, 'to_json after from_json is not a quoted string');
};

done_testing;
