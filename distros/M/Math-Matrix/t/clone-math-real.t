#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Math::Matrix::Real;

plan tests => 22;

my $xdata = [[1, 2, 3], [4, 5, 6]];

# Create an object.

my $x = Math::Matrix::Real -> new(@$xdata);
is(ref($x), 'Math::Matrix::Real', '$x is a Math::Matrix::Real');

# Create a new object.

my $y = $x -> clone();
is(ref($y), 'Math::Matrix::Real', '$y is a Math::Matrix::Real');

is_deeply([ @$x ], $xdata, '$x is unmodified');
is_deeply([ @$y ], $xdata, '$y has the same values as $x');

my ($nrow, $ncol) = $x -> size();

# Modify the new object, and verify that the original matrix is unmodified.

for my $i (0 .. $nrow - 1) {
    for my $j (0 .. $ncol - 1) {
        is(ref($y->[$i][$j]), 'Math::Real',
           "\$y->[$i][$j] is a Math::Real");
        my $oldval = $x->[$i][$j];
        ++$y->[$i][$j];
        cmp_ok($y->[$i][$j], "==", $oldval + 1,
               "trying to modify \$y->[$i][$j] does actually modify it");
        cmp_ok($y->[$i][$j], "==", $x->[$i][$j] + 1,
               "modifying \$y->[$i][$j] does not modify \$x->[$i][$j]");
    }
}
