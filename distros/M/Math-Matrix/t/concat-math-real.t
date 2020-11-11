#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Math::Matrix::Real;

plan tests => 8;

{
    my $x = Math::Matrix::Real -> new([[1, 2],
                                       [4, 5]]);
    my $y = Math::Matrix::Real -> new([[3],
                                       [6]]);
    my $z = $x -> concat($y);

    is(ref($z), 'Math::Matrix::Real', '$z is a Math::Matrix::Real');
    is_deeply([ @$z ], [[1, 2, 3],
                        [4, 5, 6]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[1, 2],
                        [4, 5]], '$x is unmodified');
    is_deeply([ @$y ], [[3],
                        [6]], '$y is unmodified');
}

{
    my $x = Math::Matrix::Real -> new([[0, 1, 2],
                                       [5, 6, 7]]);
    my $y = Math::Matrix::Real -> new([[3, 4],
                                       [8, 9]]);
    my $z = $x -> concat($y);
    is(ref($z), 'Math::Matrix::Real', '$z is a Math::Matrix::Real');
    is_deeply([ @$z ], [[0, 1, 2, 3, 4],
                        [5, 6, 7, 8, 9]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[0, 1, 2],
                        [5, 6, 7]], '$x is unmodified');
    is_deeply([ @$y ], [[3, 4],
                        [8, 9]], '$y is unmodified');
}
