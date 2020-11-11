#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 14;

note('$x -> delrow(1);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delrow(1);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  1,  2,  3,  4 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]], '$x is unmodified');
}

note('$x -> delrow([3, 1]);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delrow([3, 1]);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  1,  2,  3,  4 ],
                        [  9, 10, 11, 12 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]], '$x is unmodified');
}

note('$x -> delrow([]);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delrow([]);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]], '$x is unmodified');
}

note('$x -> delrow([0, 1, 2, 3]);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delrow([0, 1, 2, 3]);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [],
              '$y has the right values');
}

note('$x -> delrow([3.14, 1.25]);');

{
    my $x = Math::Matrix -> new([[  1,  2,  3,  4 ],
                                 [  5,  6,  7,  8 ],
                                 [  9, 10, 11, 12 ],
                                 [ 13, 14, 15, 16 ]]);
    my $y = $x -> delrow([3.14, 1.25]);

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  1,  2,  3,  4 ],
                        [  9, 10, 11, 12 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  1,  2,  3,  4 ],
                        [  5,  6,  7,  8 ],
                        [  9, 10, 11, 12 ],
                        [ 13, 14, 15, 16 ]], '$x is unmodified');
}
