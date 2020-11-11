#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 16;

note('two 2-by-2 matrices');

{
    my $x = Math::Matrix -> new([[ 1, -2],
                                 [-1,  0]]);
    my $y = Math::Matrix -> new([[ 4, -3],
                                 [ 2,  3]]);
    my $z = $x -> kron($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 4, -3, -8,  6],
                        [ 2,  3, -4, -6],
                        [-4,  3,  0,  0],
                        [-2, -3,  0,  0]],
              '$z has the right values');

    # Verify that modifying $y does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 1, -2],
                        [-1,  0]], '$x is unmodified');
    is_deeply([ @$y ], [[ 4, -3],
                        [ 2,  3]], '$y is unmodified');
}

note('2-by-2 matrix and empty matrix');

{
    my $x = Math::Matrix -> new([[ 1, -2],
                                 [-1,  0]]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> kron($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');

    # Verify that $x or $y are not modified.

    is_deeply([ @$x ], [[ 1, -2],
                        [-1,  0]], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}

note('empty matrix and 2-by-2 matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([[ 4, -3],
                                 [ 2,  3]]);
    my $z = $x -> kron($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');

    # Verify that $x or $y are not modified.

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [[ 4, -3],
                        [ 2,  3]], '$y is unmodified');
}

note('two empty matrices');

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> kron($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');

    # Verify that $x or $y are not modified.

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}
