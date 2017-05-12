use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use_ok('Math::Fraction::Egyptian');

local *sigma = \&Math::Fraction::Egyptian::sigma;

# see http://en.wikipedia.org/wiki/Practical_number
# http://www.research.att.com/~njas/sequences/A000203

is(sigma([2,1]), 3);            # 2
is(sigma([3,1]), 4);            # 3
is(sigma([2,2]), 7);            # 4
is(sigma([5,1]), 6);            # 5
is(sigma([2,1],[3,1]), 12);     # 6
is(sigma([7,1]), 8);            # 7
is(sigma([2,3]), 15);           # 8
is(sigma([3,2]), 13);           # 9
is(sigma([2,1],[5,1]), 18);     # 10

is(sigma([11,1]), 12);          # 11
is(sigma([2,2],[3,1]), 28);     # 12
is(sigma([13,1]), 14);          # 13
is(sigma([2,1],[7,1]), 24);     # 14
is(sigma([3,1],[5,1]), 24);     # 15
is(sigma([2,4]), 31);           # 16
is(sigma([17,1]), 18);          # 17
is(sigma([2,1],[3,2]), 39);     # 18
is(sigma([19,1]), 20);          # 19
is(sigma([2,2],[5,1]), 42);     # 20

# wikipedia example; n=522=2*3*3*29
is(sigma([2,1],[3,2],[29,1]), 1170);

