#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test min2
is(Func::Util::min2(3, 5), 3, 'min2: 3 is minimum');
is(Func::Util::min2(5, 3), 3, 'min2: 3 is minimum (reversed)');
is(Func::Util::min2(-5, 5), -5, 'min2: -5 is minimum');
is(Func::Util::min2(5, 5), 5, 'min2: equal values');

# Test max2
is(Func::Util::max2(3, 5), 5, 'max2: 5 is maximum');
is(Func::Util::max2(5, 3), 5, 'max2: 5 is maximum (reversed)');
is(Func::Util::max2(-5, 5), 5, 'max2: 5 is maximum');
is(Func::Util::max2(5, 5), 5, 'max2: equal values');

# Test sign
is(Func::Util::sign(5), 1, 'sign: positive returns 1');
is(Func::Util::sign(-5), -1, 'sign: negative returns -1');
is(Func::Util::sign(0), 0, 'sign: zero returns 0');

done_testing();
