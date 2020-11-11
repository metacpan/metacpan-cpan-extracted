#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 2;

my @args =
  (
   [1, 2, 3],
   [4, 5, 6],
   [],
   [[ 7,  8,  9],
    [10, 11, 12]],
  );

my $x = Math::Matrix -> new_from_cols(@args);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[1, 4, 7, 10],
                    [2, 5, 8, 11],
                    [3, 6, 9, 12]], '$x has the right values');
