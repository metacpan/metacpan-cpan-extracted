#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test stub_true - returns 1 (truthy)
ok(Func::Util::stub_true(), 'stub_true: returns truthy');

# Test stub_false - returns empty string (falsy)
ok(!Func::Util::stub_false(), 'stub_false: returns falsy');

# Test stub_zero - returns 0
is(Func::Util::stub_zero(), 0, 'stub_zero: returns 0');

# Test stub_string - returns empty string
is(Func::Util::stub_string(), '', 'stub_string: returns empty string');

# Test stub_array - returns empty array ref
my $arr = Func::Util::stub_array();
is(ref($arr), 'ARRAY', 'stub_array: returns ARRAY ref');
is_deeply($arr, [], 'stub_array: is empty array');

# Test stub_hash - returns empty hash ref
my $hash = Func::Util::stub_hash();
is(ref($hash), 'HASH', 'stub_hash: returns HASH ref');
is_deeply($hash, {}, 'stub_hash: is empty hash');

done_testing();
