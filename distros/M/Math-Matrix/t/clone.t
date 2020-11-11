#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 16;

my $xdata = [[1, 2, 3], [4, 5, 6]];

# Create an object.

my $x = Math::Matrix -> new(@$xdata);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');

# Create a new object.

my $y = $x -> clone();
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');

is_deeply([ @$x ], $xdata, '$x is unmodified');
is_deeply([ @$y ], $xdata, '$y has the same values as $x');

my ($nrow, $ncol) = $x -> size();

for my $i (0 .. $nrow - 1) {
    for my $j (0 .. $ncol - 1) {
        my $oldval = $x->[$i][$j];
        ++$y->[$i][$j];
        cmp_ok($y->[$i][$j], "==", $oldval + 1,
               "trying to modify \$y->[$i][$j] does actually modify it");
        cmp_ok($x->[$i][$j], "==", $oldval,
               "modifying \$y->[$i][$j] does not modify \$x->[$i][$j]");
    }
}
