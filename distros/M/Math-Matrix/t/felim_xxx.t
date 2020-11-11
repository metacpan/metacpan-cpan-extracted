#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 15;

note('felim_np()');

{
    my $x = Math::Matrix -> new([[  2,  2, -7,  2,  2 ],
                                 [  0, -8,  4, -2,  8 ],
                                 [ -6, -6, -3,  6, -6 ],
                                 [  4, -2,  8, -4,  2 ],
                                 [ -4,  0, -1,  5, -6 ]]);
    my $y = $x -> felim_np();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[   2,   2,  -7,   2,   2 ],
                        [   0,  -8,   4,  -2,   8 ],
                        [   0,   0, -24,  12,   0 ],
                        [   0,   0,   0,   3,  -8 ],
                        [   0,   0,   0,   0,   6 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  2,  2, -7,  2,  2 ],
                        [  0, -8,  4, -2,  8 ],
                        [ -6, -6, -3,  6, -6 ],
                        [  4, -2,  8, -4,  2 ],
                        [ -4,  0, -1,  5, -6 ]], '$x is unmodified');
}

note('felim_tp()');

{
    my $x = Math::Matrix -> new([[  2,  2, -7,  2,  2 ],
                                 [  0, -8,  4, -2,  8 ],
                                 [ -6, -6, -3,  6, -6 ],
                                 [  4, -2,  8, -4,  2 ],
                                 [ -4,  0, -1,  5, -6 ]]);
    my $y = $x -> felim_tp();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[   2,   2,  -7,   2,   2 ],
                        [   0,  -8,   4,  -2,   8 ],
                        [   0,   0, -24,  12,   0 ],
                        [   0,   0,   0,   3,  -8 ],
                        [   0,   0,   0,   0,   6 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  2,  2, -7,  2,  2 ],
                        [  0, -8,  4, -2,  8 ],
                        [ -6, -6, -3,  6, -6 ],
                        [  4, -2,  8, -4,  2 ],
                        [ -4,  0, -1,  5, -6 ]], '$x is unmodified');
}

note('felim_pp()');

{
    my $x = Math::Matrix -> new([[  2,  2, -7,  2,  2 ],
                                 [  0, -8,  4, -2,  8 ],
                                 [ -6, -6, -3,  6, -6 ],
                                 [  4, -2,  8, -4,  2 ],
                                 [ -4,  0, -1,  5, -6 ]]);
    my $y = $x -> felim_pp();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[ -6, -6, -3,  6, -6 ],
                        [  0, -8,  4, -2,  8 ],
                        [  0,  0, -8,  4,  0 ],
                        [  0,  0,  0,  3, -8 ],
                        [  0,  0,  0,  0,  6 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  2,  2, -7,  2,  2 ],
                        [  0, -8,  4, -2,  8 ],
                        [ -6, -6, -3,  6, -6 ],
                        [  4, -2,  8, -4,  2 ],
                        [ -4,  0, -1,  5, -6 ]], '$x is unmodified');
}

note('felim_sp()');

{
    my $x = Math::Matrix -> new([[  2,  2, -7,  2,  2 ],
                                 [  0, -8,  4, -2,  8 ],
                                 [ -6, -6, -3,  6, -6 ],
                                 [  4, -2,  8, -4,  2 ],
                                 [ -4,  0, -1,  5, -6 ]]);
    my $y = $x -> felim_sp();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  -6,  -6,  -3,   6,  -6 ],
                        [   0,  -8,   4,  -2,   8 ],
                        [   0,   0,  -8,   4,   0 ],
                        [   0,   0,   0, 1.5,   2 ],
                        [   0,   0,   0,   0, -12 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  2,  2, -7,  2,  2 ],
                        [  0, -8,  4, -2,  8 ],
                        [ -6, -6, -3,  6, -6 ],
                        [  4, -2,  8, -4,  2 ],
                        [ -4,  0, -1,  5, -6 ]], '$x is unmodified');
}

note('felim_fp()');

{
    my $x = Math::Matrix -> new([[  2,  2, -7,  2,  2 ],
                                 [  0, -8,  4, -2,  8 ],
                                 [ -6, -6, -3,  6, -6 ],
                                 [  4, -2,  8, -4,  2 ],
                                 [ -4,  0, -1,  5, -6 ]]);
    my $y = $x -> felim_fp();

    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[   -8,    8,    4,    0,   -2 ],
                        [    0,  -12,   -6,   -6,  7.5 ],
                        [    0,    0,   -8,    0,    4 ],
                        [    0,    0,    0,    4,    0 ],
                        [    0,    0,    0,    0, 2.25 ]],
              '$y has the right values');

    # Verify that modifying $y does not modify $x.

    my ($nrowy, $ncoly) = $y -> size();
    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {
            $y -> [$i][$j] += 100;
        }
    }

    is_deeply([ @$x ], [[  2,  2, -7,  2,  2 ],
                        [  0, -8,  4, -2,  8 ],
                        [ -6, -6, -3,  6, -6 ],
                        [  4, -2,  8, -4,  2 ],
                        [ -4,  0, -1,  5, -6 ]], '$x is unmodified');
}
