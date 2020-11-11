#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 4;

{
    my $x = Math::Matrix -> new([[-2, -1,  0],
                                 [ 1,  2,  3]]);
    my $y = $x -> neg();
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [[  2,  1,  0 ],
                        [ -1, -2, -3 ]], '$y has the right values');
}

{
    my $x = Math::Matrix -> new([]);
    my $y = $x -> neg();
    is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
    is_deeply([ @$y ], [], '$y has the right values');
}
