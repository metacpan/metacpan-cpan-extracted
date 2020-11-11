#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 36;

################################################################

note('any() on a 4-by-5 matrix');

{
    my $x = Math::Matrix -> new([[ 3, -1,  5,  2,  8 ],
                                 [ 4,  0,  2, -3,  1 ],
                                 [ 2,  6, -5,  1, -2 ],
                                 [ 0, -3,  4,  2,  3 ]]);
    my $y = $x -> any();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1, 1, 1, 1, 1 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, -1,  5,  2,  8 ],
                        [ 4,  0,  2, -3,  1 ],
                        [ 2,  6, -5,  1, -2 ],
                        [ 0, -3,  4,  2,  3 ]], '$x is unmodified');
}

note('any(1) on a 4-by-5 matrix');

{
    my $x = Math::Matrix -> new([[ 3, -1,  5,  2,  8 ],
                                 [ 4,  0,  2, -3,  1 ],
                                 [ 2,  6, -5,  1, -2 ],
                                 [ 0, -3,  4,  2,  3 ]]);
    my $y = $x -> any(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1, 1, 1, 1, 1 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, -1,  5,  2,  8 ],
                        [ 4,  0,  2, -3,  1 ],
                        [ 2,  6, -5,  1, -2 ],
                        [ 0, -3,  4,  2,  3 ]], '$x is unmodified');
}

note('any(2) on a 4-by-5 matrix');

{
    my $x = Math::Matrix -> new([[ 3, -1,  5,  2,  8 ],
                                 [ 4,  0,  2, -3,  1 ],
                                 [ 2,  6, -5,  1, -2 ],
                                 [ 0, -3,  4,  2,  3 ]]);
    my $y = $x -> any(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1 ],
                        [ 1 ],
                        [ 1 ],
                        [ 1 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, -1,  5,  2,  8 ],
                        [ 4,  0,  2, -3,  1 ],
                        [ 2,  6, -5,  1, -2 ],
                        [ 0, -3,  4,  2,  3 ]], '$x is unmodified');
}

################################################################

note('any() on a 4-by-1 matrix');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ],
                                 [ 2 ],
                                 [ 0 ]]);
    my $y = $x -> any();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ],
                        [ 2 ],
                        [ 0 ]], '$x is unmodified');
}

note('any(1) on a 4-by-1 matrix');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ],
                                 [ 2 ],
                                 [ 0 ]]);
    my $y = $x -> any(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ],
                        [ 2 ],
                        [ 0 ]], '$x is unmodified');
}

note('any(2) on a 4-by-1 matrix');

{
    my $x = Math::Matrix -> new([[ 3 ],
                                 [ 4 ],
                                 [ 2 ],
                                 [ 0 ]]);
    my $y = $x -> any(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1 ],
                        [ 1 ],
                        [ 1 ],
                        [ 0 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ],
                        [ 4 ],
                        [ 2 ],
                                 [ 0 ]], '$x is unmodified');
}

################################################################

note('any() on a 1-by-5 matrix');

{
    my $x = Math::Matrix -> new([[ 3, -1,  5,  2,  8 ]]);
    my $y = $x -> any();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, -1,  5,  2,  8 ]], '$x is unmodified');
}

note('any(1) on a 1-by-5 matrix');

{
    my $x = Math::Matrix -> new([[ 3, -1,  5,  2,  8 ]]);
    my $y = $x -> any(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1, 1, 1, 1, 1 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, -1,  5,  2,  8 ]], '$x is unmodified');
}

note('any(2) on a 1-by-5 matrix');

{
    my $x = Math::Matrix -> new([[ 3, -1,  5,  2,  8 ]]);
    my $y = $x -> any(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 1 ]], '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3, -1,  5,  2,  8 ]], '$x is unmodified');
}

################################################################

note('any() on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> any();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('any(1) on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> any(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

note('any(2) on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> any(2);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
