#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 28;

{
    my $x = Math::Matrix -> new([[-1], [0], [1]]);
    my $y = Math::Matrix -> new([[-1, 0, 1]]);
    my $z = $x -> seq($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[1, 0, 0],
                        [0, 1, 0],
                        [0, 0, 1]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-1], [0], [1]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[-1], [0], [1]]);
    my $y = Math::Matrix -> new([[-1, 0, 1]]);
    my $z = $x -> sne($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[0, 1, 1],
                        [1, 0, 1],
                        [1, 1, 0]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-1], [0], [1]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[-1], [0], [1]]);
    my $y = Math::Matrix -> new([[-1, 0, 1]]);
    my $z = $x -> slt($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[0, 1, 1],
                        [0, 0, 1],
                        [0, 0, 0]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-1], [0], [1]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[-1], [0], [1]]);
    my $y = Math::Matrix -> new([[-1, 0, 1]]);
    my $z = $x -> sle($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[1, 1, 1],
                        [0, 1, 1],
                        [0, 0, 1]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-1], [0], [1]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[-1], [0], [1]]);
    my $y = Math::Matrix -> new([[-1, 0, 1]]);
    my $z = $x -> sgt($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[0, 0, 0],
                        [1, 0, 0],
                        [1, 1, 0]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-1], [0], [1]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[-1], [0], [1]]);
    my $y = Math::Matrix -> new([[-1, 0, 1]]);
    my $z = $x -> sge($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[1, 0, 0],
                        [1, 1, 0],
                        [1, 1, 1]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-1], [0], [1]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1]], '$y is unmodified');
}

{
    my $x = Math::Matrix -> new([[-1], [0], [1]]);
    my $y = Math::Matrix -> new([[-1, 0, 1]]);
    my $z = $x -> scmp($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 0, -1, -1],
                        [ 1,  0, -1],
                        [ 1,  1,  0]], '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[-1], [0], [1]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1]], '$y is unmodified');
}
