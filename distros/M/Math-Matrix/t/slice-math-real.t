#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Math::Matrix::Real;

plan tests => 19;

my $orig = [[11 .. 19],
            [21 .. 29]];

# Create an object.

my $A = Math::Matrix::Real -> new(@$orig);

# Create a new object.

my @colidx = (1, 3, 6);
my $B = $A -> slice(@colidx);
is(ref($B), 'Math::Matrix::Real', '$B is a Math::Matrix::Real');

# Modify the new object, and verify that the original matrix is unmodified.

for my $i (0 .. 1) {
    for my $jB (0 .. @colidx - 1) {
        my $j = $colidx[$jB];
        is(ref($B->[$i][$jB]), 'Math::Real',
           "\$B->[$i][$jB] is a Math::Real");
        my $oldval = $orig->[$i][$j];
        ++$B->[$i][$jB];
        cmp_ok($B->[$i][$jB], "==", $oldval + 1,
               "trying to modify \$B->[$i][$jB] does actually modify it");
        cmp_ok($A->[$i][$j], "==", $oldval,
               "modifying \$B->[$i][$jB] does not modify \$A->[$i][$j]");
    }
}
