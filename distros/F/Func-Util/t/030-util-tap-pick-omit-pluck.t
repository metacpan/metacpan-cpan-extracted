#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test tap - takes (coderef, value), calls coderef with value, returns value
my $val = 0;
my $result = Func::Util::tap(sub { $val = $_[0] * 2 }, 42);
is($result, 42, 'tap: returns original value');
is($val, 84, 'tap: callback was executed');

# Test pick
my $hash = {a => 1, b => 2, c => 3, d => 4};
my $picked = Func::Util::pick($hash, 'a', 'c');
is_deeply($picked, {a => 1, c => 3}, 'pick: selects specified keys');

my $picked2 = Func::Util::pick($hash, 'a', 'x');
is_deeply($picked2, {a => 1}, 'pick: ignores missing keys');

# Test omit
my $omitted = Func::Util::omit($hash, 'a', 'c');
is_deeply($omitted, {b => 2, d => 4}, 'omit: excludes specified keys');

my $omitted2 = Func::Util::omit($hash, 'x', 'y');
is_deeply($omitted2, $hash, 'omit: missing keys no effect');

# Test pluck
my $objects = [
    {name => 'Alice', age => 30},
    {name => 'Bob', age => 25},
    {name => 'Carol', age => 35},
];
my $names = Func::Util::pluck($objects, 'name');
is_deeply($names, ['Alice', 'Bob', 'Carol'], 'pluck: extracts names');

my $ages = Func::Util::pluck($objects, 'age');
is_deeply($ages, [30, 25, 35], 'pluck: extracts ages');

done_testing();
