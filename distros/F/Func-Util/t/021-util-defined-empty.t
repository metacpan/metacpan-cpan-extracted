#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test is_defined
ok(Func::Util::is_defined(1), 'is_defined: 1 is defined');
ok(Func::Util::is_defined(0), 'is_defined: 0 is defined');
ok(Func::Util::is_defined(''), 'is_defined: empty string is defined');
ok(!Func::Util::is_defined(undef), 'is_defined: undef is not defined');

# Test is_true
ok(Func::Util::is_true(1), 'is_true: 1 is true');
ok(Func::Util::is_true('hello'), 'is_true: non-empty string is true');
ok(!Func::Util::is_true(0), 'is_true: 0 is not true');
ok(!Func::Util::is_true(''), 'is_true: empty string is not true');
ok(!Func::Util::is_true(undef), 'is_true: undef is not true');

# Test is_false
ok(Func::Util::is_false(0), 'is_false: 0 is false');
ok(Func::Util::is_false(''), 'is_false: empty string is false');
ok(Func::Util::is_false(undef), 'is_false: undef is false');
ok(!Func::Util::is_false(1), 'is_false: 1 is not false');
ok(!Func::Util::is_false('hello'), 'is_false: non-empty string is not false');

# Test is_empty
ok(Func::Util::is_empty(''), 'is_empty: empty string is empty');
ok(Func::Util::is_empty(undef), 'is_empty: undef is empty');
ok(!Func::Util::is_empty('hello'), 'is_empty: non-empty string is not empty');
ok(!Func::Util::is_empty(0), 'is_empty: 0 is not empty');

# Test is_empty_array
ok(Func::Util::is_empty_array([]), 'is_empty_array: empty array is empty');
ok(!Func::Util::is_empty_array([1]), 'is_empty_array: non-empty array is not empty');
ok(!Func::Util::is_empty_array('hello'), 'is_empty_array: non-array is not empty array');

# Test is_empty_hash
ok(Func::Util::is_empty_hash({}), 'is_empty_hash: empty hash is empty');
ok(!Func::Util::is_empty_hash({a => 1}), 'is_empty_hash: non-empty hash is not empty');
ok(!Func::Util::is_empty_hash('hello'), 'is_empty_hash: non-hash is not empty hash');

done_testing();
