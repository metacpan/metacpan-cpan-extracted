#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test first_eq, first_ne, first_lt, first_le, first_gt, first_ge
# These functions take (\@array, $value)
is(Func::Util::first_eq([1, 5, 3, 5], 5), 5, 'first_eq: first equal to 5');
is(Func::Util::first_eq([1, 2, 3, 4], 5), undef, 'first_eq: none equal to 5');

is(Func::Util::first_ne([5, 5, 3, 5], 5), 3, 'first_ne: first not equal to 5');
is(Func::Util::first_ne([5, 5, 5, 5], 5), undef, 'first_ne: all equal to 5');

is(Func::Util::first_lt([6, 7, 3, 8], 5), 3, 'first_lt: first less than 5');
is(Func::Util::first_lt([6, 7, 8, 9], 5), undef, 'first_lt: none less than 5');

is(Func::Util::first_le([6, 5, 8, 9], 5), 5, 'first_le: first less than or equal to 5');
is(Func::Util::first_le([6, 7, 8, 9], 5), undef, 'first_le: none less than or equal to 5');

is(Func::Util::first_gt([1, 2, 6, 4], 5), 6, 'first_gt: first greater than 5');
is(Func::Util::first_gt([1, 2, 3, 4], 5), undef, 'first_gt: none greater than 5');

is(Func::Util::first_ge([1, 2, 5, 4], 5), 5, 'first_ge: first greater than or equal to 5');
is(Func::Util::first_ge([1, 2, 3, 4], 5), undef, 'first_ge: none greater than or equal to 5');

done_testing();
