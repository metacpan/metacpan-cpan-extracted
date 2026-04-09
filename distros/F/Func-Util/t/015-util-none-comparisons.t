#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test none_eq, none_ne, none_lt, none_le, none_gt, none_ge
# These functions take (\@array, $value)
ok(Func::Util::none_eq([1, 2, 3, 4], 5), 'none_eq: none equals 5');
ok(!Func::Util::none_eq([1, 2, 5, 4], 5), 'none_eq: one equals 5');

ok(Func::Util::none_ne([5, 5, 5, 5], 5), 'none_ne: none not equal to 5 (all equal)');
ok(!Func::Util::none_ne([5, 5, 3, 5], 5), 'none_ne: one not equal to 5');

ok(Func::Util::none_lt([5, 6, 7, 8], 5), 'none_lt: none less than 5');
ok(!Func::Util::none_lt([5, 6, 4, 8], 5), 'none_lt: one less than 5');

ok(Func::Util::none_le([6, 7, 8, 9], 5), 'none_le: none less than or equal to 5');
ok(!Func::Util::none_le([6, 5, 8, 9], 5), 'none_le: one less than or equal to 5');

ok(Func::Util::none_gt([1, 2, 3, 4], 5), 'none_gt: none greater than 5');
ok(!Func::Util::none_gt([1, 2, 6, 4], 5), 'none_gt: one greater than 5');

ok(Func::Util::none_ge([1, 2, 3, 4], 5), 'none_ge: none greater than or equal to 5');
ok(!Func::Util::none_ge([1, 2, 5, 4], 5), 'none_ge: one greater than or equal to 5');

done_testing();
