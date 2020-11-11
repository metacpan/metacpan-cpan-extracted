#!perl

use strict;
use warnings;

use Test::More;

# Ensure a recent version of Math::Complex. Math Complex didn't support any way
# of cloning/copying Math::Complex objects before version 1.57.

my $min_math_complex_ver = 1.57;
eval "use Math::Complex $min_math_complex_ver";
plan skip_all => "Math::Complex $min_math_complex_ver required" if $@;

use lib 't/lib';
use Math::Matrix::Complex;

plan tests => 19;

my $orig = [[11 .. 19],
            [21 .. 29]];

# Create an object.

my $A = Math::Matrix::Complex -> new(@$orig);

# Create a new object.

my @colidx = (1, 3, 6);
my $B = $A -> slice(@colidx);
is(ref($B), 'Math::Matrix::Complex', '$B is a Math::Matrix::Complex');

# Modify the new object, and verify that the original matrix is unmodified.

for my $i (0 .. 1) {
    for my $jB (0 .. @colidx - 1) {
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
