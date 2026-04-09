#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test final_eq, final_ne, final_lt, final_le, final_gt, final_ge
# These functions take (\@array, $value)
is(Func::Util::final_eq([1, 5, 3, 5], 5), 5, 'final_eq: last equal to 5');
is(Func::Util::final_eq([1, 2, 3, 4], 5), undef, 'final_eq: none equal to 5');

is(Func::Util::final_ne([5, 3, 5, 2], 5), 2, 'final_ne: last not equal to 5');
is(Func::Util::final_ne([5, 5, 5, 5], 5), undef, 'final_ne: all equal to 5');

is(Func::Util::final_lt([6, 7, 3, 8, 2], 5), 2, 'final_lt: last less than 5');
is(Func::Util::final_lt([6, 7, 8, 9], 5), undef, 'final_lt: none less than 5');

is(Func::Util::final_le([6, 5, 8, 4], 5), 4, 'final_le: last less than or equal to 5');
is(Func::Util::final_le([6, 7, 8, 9], 5), undef, 'final_le: none less than or equal to 5');

is(Func::Util::final_gt([1, 6, 3, 7], 5), 7, 'final_gt: last greater than 5');
is(Func::Util::final_gt([1, 2, 3, 4], 5), undef, 'final_gt: none greater than 5');

is(Func::Util::final_ge([1, 5, 3, 6], 5), 6, 'final_ge: last greater than or equal to 5');
is(Func::Util::final_ge([1, 2, 3, 4], 5), undef, 'final_ge: none greater than or equal to 5');

done_testing();
