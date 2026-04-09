#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use_ok('Func::Util', qw(is_even is_odd is_between));

# ============================================
# is_even tests - single bitwise AND
# ============================================

ok(is_even(0), '0 is even');
ok(is_even(2), '2 is even');
ok(is_even(4), '4 is even');
ok(is_even(-2), '-2 is even');
ok(is_even(-4), '-4 is even');
ok(is_even(100), '100 is even');
ok(is_even("2"), '"2" string is even');
ok(is_even("100"), '"100" string is even');
ok(is_even(2.0), '2.0 (whole number) is even');

ok(!is_even(1), '1 is not even');
ok(!is_even(3), '3 is not even');
ok(!is_even(-1), '-1 is not even');
ok(!is_even(-3), '-3 is not even');
ok(!is_even(101), '101 is not even');
ok(!is_even("hello"), '"hello" is not even');
ok(!is_even(undef), 'undef is not even');
ok(!is_even([]), 'arrayref is not even');
ok(!is_even(1.5), '1.5 is not even (not integer)');

# ============================================
# is_odd tests - single bitwise AND
# ============================================

ok(is_odd(1), '1 is odd');
ok(is_odd(3), '3 is odd');
ok(is_odd(5), '5 is odd');
ok(is_odd(-1), '-1 is odd');
ok(is_odd(-3), '-3 is odd');
ok(is_odd(101), '101 is odd');
ok(is_odd("3"), '"3" string is odd');
ok(is_odd("101"), '"101" string is odd');
ok(is_odd(3.0), '3.0 (whole number) is odd');

ok(!is_odd(0), '0 is not odd');
ok(!is_odd(2), '2 is not odd');
ok(!is_odd(-2), '-2 is not odd');
ok(!is_odd(100), '100 is not odd');
ok(!is_odd("hello"), '"hello" is not odd');
ok(!is_odd(undef), 'undef is not odd');
ok(!is_odd([]), 'arrayref is not odd');
ok(!is_odd(2.5), '2.5 is not odd (not integer)');

# ============================================
# is_between tests - range check (inclusive)
# ============================================

ok(is_between(5, 1, 10), '5 is between 1 and 10');
ok(is_between(1, 1, 10), '1 is between 1 and 10 (inclusive)');
ok(is_between(10, 1, 10), '10 is between 1 and 10 (inclusive)');
ok(is_between(0, -5, 5), '0 is between -5 and 5');
ok(is_between(-3, -5, -1), '-3 is between -5 and -1');
ok(is_between(3.14, 3, 4), '3.14 is between 3 and 4');
ok(is_between("5", 1, 10), '"5" string is between 1 and 10');

ok(!is_between(0, 1, 10), '0 is not between 1 and 10');
ok(!is_between(11, 1, 10), '11 is not between 1 and 10');
ok(!is_between(-6, -5, -1), '-6 is not between -5 and -1');
ok(!is_between("hello", 1, 10), '"hello" is not between 1 and 10');
ok(!is_between(undef, 1, 10), 'undef is not between 1 and 10');

# ============================================
# Test with variables (ensures custom ops work)
# ============================================

my $even = 42;
my $odd = 43;
my $in_range = 5;
my $out_range = 100;

ok(is_even($even), 'variable even value');
ok(!is_even($odd), 'variable odd value is not even');
ok(is_odd($odd), 'variable odd value');
ok(!is_odd($even), 'variable even value is not odd');

ok(is_between($in_range, 1, 10), 'variable in range');
ok(!is_between($out_range, 1, 10), 'variable out of range');

# ============================================
# Test return values
# ============================================

is(is_even(2), 1, 'is_even returns 1 for true');
is(is_even(1), '', 'is_even returns empty string for false');

is(is_odd(1), 1, 'is_odd returns 1 for true');
is(is_odd(2), '', 'is_odd returns empty string for false');

is(is_between(5, 1, 10), 1, 'is_between returns 1 for true');
is(is_between(0, 1, 10), '', 'is_between returns empty string for false');

done_testing;
