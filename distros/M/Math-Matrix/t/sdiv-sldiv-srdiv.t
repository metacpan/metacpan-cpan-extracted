#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 24;

################################################################

note('sdiv() with non-empty matrices');

{
    my $x = Math::Matrix -> new([[-3], [-2], [-1], [0], [1], [2], [3]]);
    my $y = Math::Matrix -> new([[ -4, -2, -1, 1, 2, 4 ]]);
    my $z = $x -> sdiv($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 0.75,  1.50,  3.00, -3.00, -1.50, -0.75],
                        [ 0.50,  1.00,  2.00, -2.00, -1.00, -0.50],
                        [ 0.25,  0.50,  1.00, -1.00, -0.50, -0.25],
                        [-0.00, -0.00, -0.00,  0.00,  0.00,  0.00],
                        [-0.25, -0.50, -1.00,  1.00,  0.50,  0.25],
                        [-0.50, -1.00, -2.00,  2.00,  1.00,  0.50],
                        [-0.75, -1.50, -3.00,  3.00,  1.50,  0.75]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-3], [-2], [-1], [0], [1], [2], [3]], '$x is unmodified');
    is_deeply([ @$y ], [[ -4, -2, -1, 1, 2, 4 ]], '$y is unmodified');
}

note('sdiv() with empty matrices');

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> sdiv($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}

################################################################

note('sldiv() with non-empty matrices');

{
    my $x = Math::Matrix -> new([[-3], [-2], [-1], [0], [1], [2], [3]]);
    my $y = Math::Matrix -> new([[ -4, -2, -1, 1, 2, 4 ]]);
    my $z = $x -> sldiv($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 0.75,  1.50,  3.00, -3.00, -1.50, -0.75],
                        [ 0.50,  1.00,  2.00, -2.00, -1.00, -0.50],
                        [ 0.25,  0.50,  1.00, -1.00, -0.50, -0.25],
                        [-0.00, -0.00, -0.00,  0.00,  0.00,  0.00],
                        [-0.25, -0.50, -1.00,  1.00,  0.50,  0.25],
                        [-0.50, -1.00, -2.00,  2.00,  1.00,  0.50],
                        [-0.75, -1.50, -3.00,  3.00,  1.50,  0.75]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-3], [-2], [-1], [0], [1], [2], [3]], '$x is unmodified');
    is_deeply([ @$y ], [[ -4, -2, -1, 1, 2, 4 ]], '$y is unmodified');
}

note('sldiv() with empty matrices');

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> sldiv($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}

################################################################

note('srdiv() with non-empty matrices');

{
    my $x = Math::Matrix -> new([[-3], [-2], [-1], [0], [1], [2], [3]]);
    my $y = Math::Matrix -> new([[ -4, -2, -1, 1, 2, 4 ]]);
    my $z = $x -> srdiv($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 0.75,  1.50,  3.00, -3.00, -1.50, -0.75],
                        [ 0.50,  1.00,  2.00, -2.00, -1.00, -0.50],
                        [ 0.25,  0.50,  1.00, -1.00, -0.50, -0.25],
                        [-0.00, -0.00, -0.00,  0.00,  0.00,  0.00],
                        [-0.25, -0.50, -1.00,  1.00,  0.50,  0.25],
                        [-0.50, -1.00, -2.00,  2.00,  1.00,  0.50],
                        [-0.75, -1.50, -3.00,  3.00,  1.50,  0.75]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-3], [-2], [-1], [0], [1], [2], [3]], '$x is unmodified');
    is_deeply([ @$y ], [[ -4, -2, -1, 1, 2, 4 ]], '$y is unmodified');
}

note('srdiv() with empty matrices');

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> srdiv($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowz, $ncolz) = $z -> size();
    for my $i (0 .. $nrowz - 1) {
        for my $j (0 .. $ncolz - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}
