#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 14;

note("ssub() with two matrices");

{
    my $x = Math::Matrix -> new([[  5, -2,  4 ],
                                 [ -1,  3,  2 ]]);
    my $y = Math::Matrix -> new([[  4,  3,  2 ],
                                 [ -1, -2,  6 ]]);
    my $z = $x -> ssub($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 1, -5,  2],
                        [ 0,  5, -4]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  5, -2,  4 ],
                        [ -1,  3,  2 ]], '$x is unmodified');
    is_deeply([ @$y ], [[  4,  3,  2 ],
                        [ -1, -2,  6 ]], '$y is unmodified');
}

note("ssub() with matrix and scalar");

{
    my $x = Math::Matrix -> new([[  5, -2,  4 ],
                                 [ -1,  3,  2 ]]);
    my $y = Math::Matrix -> new([[ 3 ]]);
    my $z = $x -> ssub($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[  2, -5,  1 ],
                        [ -4,  0, -1 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  5, -2,  4 ],
                        [ -1,  3,  2 ]], '$x is unmodified');
    is_deeply([ @$y ], [[ 3 ]], '$y is unmodified');
}

note("ssub() with scalar and matrix");

{
    my $x = Math::Matrix -> new([[ 3 ]]);
    my $y = Math::Matrix -> new([[  5, -2,  4 ],
                                 [ -1,  3,  2 ]]);
    my $z = $x -> ssub($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ -2,  5, -1 ],
                        [  4,  0,  1 ]],
              '$z has the right values');

    # Verify that modifying $z does not modify $x or $y.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $z -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[ 3 ]], '$x is unmodified');
    is_deeply([ @$y ], [[  5, -2,  4 ],
                        [ -1,  3,  2 ]], '$y is unmodified');
}

note("ssub() with empty matrices");

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);
    my $z = $x -> ssub($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [], '$z has the right values');
}
