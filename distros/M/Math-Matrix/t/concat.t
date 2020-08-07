#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 4;

{
    my $x = Math::Matrix -> new([1, 2], [4, 5]);
    my $y = Math::Matrix -> new([3], [6]);
    my $z = $x -> concat($y);

    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 1, 2, 3 ],
                        [ 4, 5, 6 ]], '$z has the right values');
}

{
    my $x = Math::Matrix -> new([0, 1, 2], [5, 6, 7]);
    my $y = Math::Matrix -> new([3, 4], [8, 9]);
    my $z = $x -> concat($y);
    is(ref($z), 'Math::Matrix', '$z is a Math::Matrix');
    is_deeply([ @$z ], [[ 0, 1, 2, 3, 4 ],
                        [ 5, 6, 7, 8, 9 ]], '$z has the right values');
}
