#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 2;

my $A = Math::Matrix -> new([ 11 .. 19 ],
                            [ 21 .. 29 ]);
my $B = $A -> slice(1, 3, 6);

is(ref($B), 'Math::Matrix', '$B is a Math::Matrix');
is_deeply([ @$B ], [[ 12, 14, 17 ],
                    [ 22, 24, 27 ]], '$B has the right values');
