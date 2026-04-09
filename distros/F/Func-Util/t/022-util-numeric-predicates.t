#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test is_num
ok(Func::Util::is_num(42), 'is_num: integer is num');
ok(Func::Util::is_num(3.14), 'is_num: float is num');
ok(Func::Util::is_num(-5), 'is_num: negative is num');
ok(Func::Util::is_num('42'), 'is_num: numeric string is num');
ok(!Func::Util::is_num('hello'), 'is_num: string is not num');
ok(!Func::Util::is_num('42abc'), 'is_num: mixed string is not num');

# Test is_int
ok(Func::Util::is_int(42), 'is_int: integer is int');
ok(Func::Util::is_int(-5), 'is_int: negative integer is int');
ok(Func::Util::is_int(0), 'is_int: zero is int');
ok(!Func::Util::is_int(3.14), 'is_int: float is not int');
ok(!Func::Util::is_int('hello'), 'is_int: string is not int');

# Test is_positive
ok(Func::Util::is_positive(5), 'is_positive: 5 is positive');
ok(Func::Util::is_positive(0.1), 'is_positive: 0.1 is positive');
ok(!Func::Util::is_positive(0), 'is_positive: 0 is not positive');
ok(!Func::Util::is_positive(-5), 'is_positive: -5 is not positive');

# Test is_negative
ok(Func::Util::is_negative(-5), 'is_negative: -5 is negative');
ok(Func::Util::is_negative(-0.1), 'is_negative: -0.1 is negative');
ok(!Func::Util::is_negative(0), 'is_negative: 0 is not negative');
ok(!Func::Util::is_negative(5), 'is_negative: 5 is not negative');

# Test is_zero
ok(Func::Util::is_zero(0), 'is_zero: 0 is zero');
ok(Func::Util::is_zero(0.0), 'is_zero: 0.0 is zero');
ok(!Func::Util::is_zero(1), 'is_zero: 1 is not zero');
ok(!Func::Util::is_zero(-1), 'is_zero: -1 is not zero');

# Test is_even
ok(Func::Util::is_even(0), 'is_even: 0 is even');
ok(Func::Util::is_even(2), 'is_even: 2 is even');
ok(Func::Util::is_even(-4), 'is_even: -4 is even');
ok(!Func::Util::is_even(1), 'is_even: 1 is not even');
ok(!Func::Util::is_even(3), 'is_even: 3 is not even');

# Test is_odd
ok(Func::Util::is_odd(1), 'is_odd: 1 is odd');
ok(Func::Util::is_odd(3), 'is_odd: 3 is odd');
ok(Func::Util::is_odd(-5), 'is_odd: -5 is odd');
ok(!Func::Util::is_odd(0), 'is_odd: 0 is not odd');
ok(!Func::Util::is_odd(2), 'is_odd: 2 is not odd');

# Test is_between
ok(Func::Util::is_between(5, 1, 10), 'is_between: 5 is between 1 and 10');
ok(Func::Util::is_between(1, 1, 10), 'is_between: 1 is between 1 and 10 (inclusive)');
ok(Func::Util::is_between(10, 1, 10), 'is_between: 10 is between 1 and 10 (inclusive)');
ok(!Func::Util::is_between(0, 1, 10), 'is_between: 0 is not between 1 and 10');
ok(!Func::Util::is_between(11, 1, 10), 'is_between: 11 is not between 1 and 10');

done_testing();
