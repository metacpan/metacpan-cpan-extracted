#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 16;

note("spow() with two matrices");

{
    my $x = Math::Matrix -> new([[  0, -2 ],
                                 [  1,  4 ]]);
    my $y = Math::Matrix -> new([[ 0 ]]);
    my $z = $x -> spow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 1, 1 ],
                        [ 1, 1 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  0, -2 ],
                        [  1,  4 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 0 ]], '$y is unmodified');
}

note("spow() with matrix and scalar");

{
    my $x = Math::Matrix -> new([[ 0, -2 ],
                                 [ 1,  4 ]]);
    my $y = Math::Matrix -> new([[ 3 ]]);
    my $z = $x -> spow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 0, -8 ],
                        [ 1, 64 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 0, -2 ],
                        [ 1,  4 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 3 ]], '$y is unmodified');
}

note("spow() with scalar and matrix");

{
    my $x = Math::Matrix -> new([[ 2 ]]);
    my $y = Math::Matrix -> new([[ -2, -1, 0 ],
                                 [  1,  2, 3 ]]);
    my $z = $x -> spow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 0.25, 0.5, 1 ],
                        [ 2,    4,   8 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 2 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ -2, -1, 0 ],
                        [  1,  2, 3 ]], '$y is unmodified');
}

note("spow() with empty matrices");

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> spow($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [],
              '$z has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}
