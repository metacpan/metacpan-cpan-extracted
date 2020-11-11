#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 15;

################################################################

note('abs() on a non-empty matrix');

{
    my $x = Math::Matrix -> new([[ -2.75, -2.50, -2.25, -2.00 ],
                                 [ -1.75, -1.50, -1.25, -1.00 ],
                                 [ -0.75, -0.50, -0.25, -0.00 ],
                                 [  0.75,  0.50,  0.25,  0.00 ],
                                 [  1.75,  1.50,  1.25,  1.00 ],
                                 [  2.75,  2.50,  2.25,  2.00 ]]);
    my $y = $x -> abs();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 2.75, 2.50, 2.25, 2.00 ],
                        [ 1.75, 1.50, 1.25, 1.00 ],
                        [ 0.75, 0.50, 0.25, 0.00 ],
                        [ 0.75, 0.50, 0.25, 0.00 ],
                        [ 1.75, 1.50, 1.25, 1.00 ],
                        [ 2.75, 2.50, 2.25, 2.00 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -2.75, -2.50, -2.25, -2.00 ],
                        [ -1.75, -1.50, -1.25, -1.00 ],
                        [ -0.75, -0.50, -0.25, -0.00 ],
                        [  0.75,  0.50,  0.25,  0.00 ],
                        [  1.75,  1.50,  1.25,  1.00 ],
                        [  2.75,  2.50,  2.25,  2.00 ]], '$x is unmodified');
}

note('abs() on a non-empty matrix (overloading)');

{
    my $x = Math::Matrix -> new([[ -2.75, -2.50, -2.25, -2.00 ],
                                 [ -1.75, -1.50, -1.25, -1.00 ],
                                 [ -0.75, -0.50, -0.25, -0.00 ],
                                 [  0.75,  0.50,  0.25,  0.00 ],
                                 [  1.75,  1.50,  1.25,  1.00 ],
                                 [  2.75,  2.50,  2.25,  2.00 ]]);
    my $y = abs($x);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ 2.75, 2.50, 2.25, 2.00 ],
                        [ 1.75, 1.50, 1.25, 1.00 ],
                        [ 0.75, 0.50, 0.25, 0.00 ],
                        [ 0.75, 0.50, 0.25, 0.00 ],
                        [ 1.75, 1.50, 1.25, 1.00 ],
                        [ 2.75, 2.50, 2.25, 2.00 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -2.75, -2.50, -2.25, -2.00 ],
                        [ -1.75, -1.50, -1.25, -1.00 ],
                        [ -0.75, -0.50, -0.25, -0.00 ],
                        [  0.75,  0.50,  0.25,  0.00 ],
                        [  1.75,  1.50,  1.25,  1.00 ],
                        [  2.75,  2.50,  2.25,  2.00 ]], '$x is unmodified');
}

note('abs() on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> abs();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}

################################################################

note('sign() on a non-empty matrix');

{
    my $x = Math::Matrix -> new([[ -2.75, -2.50, -2.25, -2.00 ],
                                 [ -1.75, -1.50, -1.25, -1.00 ],
                                 [ -0.75, -0.50, -0.25, -0.00 ],
                                 [  0.75,  0.50,  0.25,  0.00 ],
                                 [  1.75,  1.50,  1.25,  1.00 ],
                                 [  2.75,  2.50,  2.25,  2.00 ]]);
    my $y = $x -> sign();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ -1, -1, -1, -1 ],
                        [ -1, -1, -1, -1 ],
                        [ -1, -1, -1,  0 ],
                        [  1,  1,  1,  0 ],
                        [  1,  1,  1,  1 ],
                        [  1,  1,  1,  1 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ -2.75, -2.50, -2.25, -2.00 ],
                        [ -1.75, -1.50, -1.25, -1.00 ],
                        [ -0.75, -0.50, -0.25, -0.00 ],
                        [  0.75,  0.50,  0.25,  0.00 ],
                        [  1.75,  1.50,  1.25,  1.00 ],
                        [  2.75,  2.50,  2.25,  2.00 ]], '$x is unmodified');
}

note('sign() on an empty matrix');

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> sign();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
    is_deeply([ @$x ], [], '$x is unmodified');
}
