#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test all_eq, all_ne, all_lt, all_le, all_gt, all_ge
# These functions take (\@array, $value)
ok(Func::Util::all_eq([5, 5, 5, 5], 5), 'all_eq: all equal to 5');
ok(!Func::Util::all_eq([5, 5, 6, 5], 5), 'all_eq: not all equal to 5');

ok(Func::Util::all_ne([1, 2, 3, 4], 5), 'all_ne: all not equal to 5');
ok(!Func::Util::all_ne([1, 2, 5, 4], 5), 'all_ne: one equals 5');

ok(Func::Util::all_lt([1, 2, 3, 4], 5), 'all_lt: all less than 5');
ok(!Func::Util::all_lt([1, 2, 5, 4], 5), 'all_lt: one not less than 5');

ok(Func::Util::all_le([1, 2, 5, 4], 5), 'all_le: all less than or equal to 5');
ok(!Func::Util::all_le([1, 2, 6, 4], 5), 'all_le: one greater than 5');

ok(Func::Util::all_gt([1, 2, 3, 4], 0), 'all_gt: all greater than 0');
ok(!Func::Util::all_gt([1, 2, 3, 4], 2), 'all_gt: one not greater than 2');

ok(Func::Util::all_ge([1, 2, 3, 4], 1), 'all_ge: all greater than or equal to 1');
ok(!Func::Util::all_ge([1, 2, 3, 4], 2), 'all_ge: one less than 2');

done_testing();
