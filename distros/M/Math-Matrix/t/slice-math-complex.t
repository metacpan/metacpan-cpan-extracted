#!perl

# Test when each element is a numerical object. This is to verify that each
# element in the returned matrix is a different object than the corresponding
# object in the invocand matrix.

use strict;
use warnings;

use lib 't/lib';
use Math::Matrix::Complex;

use Test::More tests => 19;

my $orig = [[ 11 .. 19 ],
            [ 21 .. 29 ]];

# Create an object.

my $A = Math::Matrix::Complex -> new(@$orig);

# Create a new object.

my @colidx = (1, 3, 6);
my $B = $A -> slice(@colidx);
is(ref($B), 'Math::Matrix::Complex', '$B is a Math::Matrix::Complex');

# Modify the new object, and verify that the original matrix is unmodified.

for (my $i = 0 ; $i < 2 ; ++$i) {
    for (my $jB = 0 ; $jB < @colidx ; ++$jB) {
        my $j = $colidx[$jB];
        is(ref($B->[$i][$jB]), 'Math::Complex',
           "\$B->[$i][$jB] is a Math::Complex");
        my $oldval = $orig->[$i][$j];
        ++$B->[$i][$jB];
        cmp_ok($B->[$i][$jB], "==", $oldval + 1,
               "trying to modify \$B->[$i][$jB] does actually modify it");
        cmp_ok($A->[$i][$j], "==", $oldval,
               "modifying \$B->[$i][$jB] does not modify \$A->[$i][$j]");
    }
}
