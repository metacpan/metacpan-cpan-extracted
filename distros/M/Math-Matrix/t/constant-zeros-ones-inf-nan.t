#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 25;

my ($x, $nrow, $ncol);

# constant()

$x = Math::Matrix -> constant(7, 2, 3);
is_deeply([ @$x ], [[7, 7, 7], [7, 7, 7]],
          '$x = Math::Matrix -> constant(7, 2, 3);');

$x = Math::Matrix -> constant(7, 1, 3);
is_deeply([ @$x ], [[7, 7, 7]],
          '$x = Math::Matrix -> constant(7, 1, 3);');

$x = Math::Matrix -> constant(7, 3, 1);
is_deeply([ @$x ], [[7], [7], [7]],
          '$x = Math::Matrix -> constant(7, 3, 1);');

$x = Math::Matrix -> constant(7, 3);
is_deeply([ @$x ], [[7, 7, 7], [7, 7, 7], [7, 7, 7]],
          '$x = Math::Matrix -> constant(7, 3);');

$x = Math::Matrix -> constant(7);
is_deeply([ @$x ], [[7]],
          '$x = Math::Matrix -> constant(7);');

# zeros()

$x = Math::Matrix -> zeros(2, 3);
is_deeply([ @$x ], [[0, 0, 0], [0, 0, 0]],
          '$x = Math::Matrix -> zeros(2, 3);');

$x = Math::Matrix -> zeros(1, 3);
is_deeply([ @$x ], [[0, 0, 0]],
          '$x = Math::Matrix -> zeros(1, 3);');

$x = Math::Matrix -> zeros(3, 1);
is_deeply([ @$x ], [[0], [0], [0]],
          '$x = Math::Matrix -> zeros(3, 1);');

$x = Math::Matrix -> zeros(3);
is_deeply([ @$x ], [[0, 0, 0], [0, 0, 0], [0, 0, 0]],
          '$x = Math::Matrix -> zeros(3);');

$x = Math::Matrix -> zeros();
is_deeply([ @$x ], [[0]],
          '$x = Math::Matrix -> zeros();');

# ones()

$x = Math::Matrix -> ones(2, 3);
is_deeply([ @$x ], [[1, 1, 1], [1, 1, 1]],
          '$x = Math::Matrix -> ones(2, 3);');

$x = Math::Matrix -> ones(1, 3);
is_deeply([ @$x ], [[1, 1, 1]],
          '$x = Math::Matrix -> ones(1, 3);');

$x = Math::Matrix -> ones(3, 1);
is_deeply([ @$x ], [[1], [1], [1]],
          '$x = Math::Matrix -> ones(3, 1);');

$x = Math::Matrix -> ones(3);
is_deeply([ @$x ], [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
          '$x = Math::Matrix -> ones(3);');

$x = Math::Matrix -> ones();
is_deeply([ @$x ], [[1]],
          '$x = Math::Matrix -> ones();');

require Math::Trig;
my $inf  = Math::Trig::Inf();
my $nan  = $inf - $inf;

# inf()

$x = Math::Matrix -> inf(2, 3);
is_deeply([ @$x ], [[$inf, $inf, $inf],
                    [$inf, $inf, $inf]],
          '$x = Math::Matrix -> inf(2, 3);');

$x = Math::Matrix -> inf(1, 3);
is_deeply([ @$x ], [[$inf, $inf, $inf]],
          '$x = Math::Matrix -> inf(1, 3);');

$x = Math::Matrix -> inf(3, 1);
is_deeply([ @$x ], [[$inf], [$inf], [$inf]],
          '$x = Math::Matrix -> inf(3, 1);');

$x = Math::Matrix -> inf(3);
is_deeply([ @$x ], [[$inf, $inf, $inf],
                    [$inf, $inf, $inf],
                    [$inf, $inf, $inf]],
          '$x = Math::Matrix -> inf(3);');

$x = Math::Matrix -> inf();
is_deeply([ @$x ], [[$inf]],
          '$x = Math::Matrix -> inf();');

# nan()

$x = Math::Matrix -> nan(2, 3);
is_deeply([ @$x ], [[$nan, $nan, $nan],
                    [$nan, $nan, $nan]],
          '$x = Math::Matrix -> nan(2, 3);');

$x = Math::Matrix -> nan(1, 3);
is_deeply([ @$x ], [[$nan, $nan, $nan]],
          '$x = Math::Matrix -> nan(1, 3);');

$x = Math::Matrix -> nan(3, 1);
is_deeply([ @$x ], [[$nan], [$nan], [$nan]],
          '$x = Math::Matrix -> nan(3, 1);');

$x = Math::Matrix -> nan(3);
is_deeply([ @$x ], [[$nan, $nan, $nan],
                    [$nan, $nan, $nan],
                    [$nan, $nan, $nan]],
          '$x = Math::Matrix -> nan(3);');

$x = Math::Matrix -> nan();
is_deeply([ @$x ], [[$nan]],
          '$x = Math::Matrix -> nan();');
