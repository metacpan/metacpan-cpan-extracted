#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test any_eq, any_ne, any_lt, any_le, any_gt, any_ge
# These functions take (\@array, $value)
ok(Func::Util::any_eq([1, 2, 5, 4], 5), 'any_eq: one equals 5');
ok(!Func::Util::any_eq([1, 2, 3, 4], 5), 'any_eq: none equals 5');

ok(Func::Util::any_ne([5, 5, 3, 5], 5), 'any_ne: one not equal to 5');
ok(!Func::Util::any_ne([5, 5, 5, 5], 5), 'any_ne: all equal to 5');

ok(Func::Util::any_lt([6, 7, 3, 8], 5), 'any_lt: one less than 5');
ok(!Func::Util::any_lt([6, 7, 8, 9], 5), 'any_lt: none less than 5');

ok(Func::Util::any_le([6, 5, 8, 9], 5), 'any_le: one less than or equal to 5');
ok(!Func::Util::any_le([6, 7, 8, 9], 5), 'any_le: none less than or equal to 5');

ok(Func::Util::any_gt([1, 2, 6, 4], 5), 'any_gt: one greater than 5');
ok(!Func::Util::any_gt([1, 2, 3, 4], 5), 'any_gt: none greater than 5');

ok(Func::Util::any_ge([1, 2, 5, 4], 5), 'any_ge: one greater than or equal to 5');
ok(!Func::Util::any_ge([1, 2, 3, 4], 5), 'any_ge: none greater than or equal to 5');

done_testing();
