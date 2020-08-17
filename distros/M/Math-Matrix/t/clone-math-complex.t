#!perl

use strict;
use warnings;

use Test::More;

# Ensure a recent version of Math::Complex. Math Complex didn't support any way
# of cloning/copying Math::Complex objects before version 1.57.

my $min_math_complex_ver = 1.57;
eval "use Math::Complex $min_math_complex_ver";
plan skip_all => "Math::Complex $min_math_complex_ver required" if $@;

plan tests => 22;

use lib 't/lib';
use Math::Matrix::Complex;

my $xdata = [[1, 2, 3], [4, 5, 6]];

# Create an object.

my $x = Math::Matrix::Complex -> new(@$xdata);
is(ref($x), 'Math::Matrix::Complex', '$x is a Math::Matrix::Complex');

# Create a new object.

my $y = $x -> clone();
is(ref($y), 'Math::Matrix::Complex', '$y is a Math::Matrix::Complex');

is_deeply([ @$x ], $xdata, '$x is unmodified');
is_deeply([ @$y ], $xdata, '$y has the same values as $x');

my ($nrow, $ncol) = $x -> size();

# Modify the new object, and verify that the original matrix is unmodified.

for (my $i = 0 ; $i < $nrow ; ++$i) {
    for (my $j = 0 ; $j < $ncol ; ++$j) {
        is(ref($y->[$i][$j]), 'Math::Complex',
           "\$y->[$i][$j] is a Math::Complex");
        my $oldval = $x->[$i][$j];
        ++$y->[$i][$j];
        cmp_ok($y->[$i][$j], "==", $oldval + 1,
               "trying to modify \$y->[$i][$j] does actually modify it");
        cmp_ok($y->[$i][$j], "==", $x->[$i][$j] + 1,
               "modifying \$y->[$i][$j] does not modify \$x->[$i][$j]");
    }
}
