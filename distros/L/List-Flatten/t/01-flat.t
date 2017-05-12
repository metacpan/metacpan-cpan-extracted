#!perl -T

use Test::More tests => 4;

use List::Flatten;

my @foo = (1, 2, [3, 4, 5], 6, [7, 8], 9);
my @bar = flat @foo;
is(int @bar, 9, 'flattened correctly');
is($bar[4], 5, 'element 5 correctly interpolated');

# check for empty arrayrefs
my @bar2 = flat 1, 2, [], 3;
is(int @bar2, 3, 'flattened empty arrayref correctly');
is($bar2[2], 3, 'element 3 correctly interpolated');




