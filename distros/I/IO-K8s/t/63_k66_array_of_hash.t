#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use IO::K8s;
use IO::K8s::AutoGen;

# k66: AutoGen mapped items: object and items: array onto [ Str ], so
# schema-conforming hashrefs / arrayrefs died on ArrayRef[Str]. The DSL had no
# array-of-hash and no array-of-array form. This adds [ {} ] (array of opaque
# hashes) and [ [] ] (array of opaque arrays), then points AutoGen at them.

# --- The DSL forms directly ---
{
    package Test::Karr66::Thing;
    use IO::K8s::Resource;
    k8s rows    => [ {} ];   # array of opaque hashes
    k8s matrix  => [ [] ];   # array of opaque arrays
}

my $hand = Test::Karr66::Thing->new(
    rows   => [ { a => 1 }, { b => 2 } ],
    matrix => [ [1, 2], [3, 4] ],
);
cmp_deeply($hand->TO_JSON->{rows}, [ { a => 1 }, { b => 2 } ],
           'array-of-hash accepts and round-trips hashrefs');
cmp_deeply($hand->TO_JSON->{matrix}, [ [1, 2], [3, 4] ],
           'array-of-array accepts and round-trips arrayrefs');

# The old behaviour was a hard type failure -- a hashref is not a Str.
eval { Test::Karr66::Thing->new(rows => 'not-an-array') };
ok($@, 'a non-arrayref is still rejected');

# --- AutoGen maps items: object / items: array onto them ---
IO::K8s::AutoGen::clear_cache();
my $schema = { type => 'object', properties => {
    objs => { type => 'array', items => { type => 'object' } },
    arrs => { type => 'array', items => { type => 'array'  } },
} };
my $class = IO::K8s::AutoGen::get_or_generate(
    'com.example.v1.NestedThing', $schema, {}, 'IO::K8s::_AUTOGEN_karr66');

my $obj = $class->new(
    objs => [ { name => 'x' }, { name => 'y' } ],
    arrs => [ ['a', 'b'], ['c'] ],
);
cmp_deeply($obj->TO_JSON->{objs}, [ { name => 'x' }, { name => 'y' } ],
           'AutoGen items:object accepts an array of hashrefs');
cmp_deeply($obj->TO_JSON->{arrs}, [ ['a', 'b'], ['c'] ],
           'AutoGen items:array accepts an array of arrayrefs');

# Round-trip through inflate keeps the nested structures intact.
my $back = $class->FROM_HASH($obj->TO_JSON);
cmp_deeply($back->TO_JSON->{objs}, [ { name => 'x' }, { name => 'y' } ],
           'nested hashes survive FROM_HASH round-trip');

done_testing;
