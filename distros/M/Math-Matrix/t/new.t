#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 41;

my ($x, $y);

###############################################################################

note("\n\$x = Math::Matrix -> new([1, 2, 3], [4, 5, 6]);\n\n");
$x = Math::Matrix -> new([1, 2, 3], [4, 5, 6]);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[1, 2, 3], [4, 5, 6]], '$x has the right values');

note("\n\$x = Math::Matrix -> new([[1, 2, 3], [4, 5, 6]]);\n\n");
$x = Math::Matrix -> new([[1, 2, 3], [4, 5, 6]]);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[1, 2, 3], [4, 5, 6]], '$x has the right values');

note("\n\$x = Math::Matrix -> new([1, 2, 3]);\n\n");
$x = Math::Matrix -> new([1, 2, 3]);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[1, 2, 3]], '$x has the right values');

note("\n\$x = Math::Matrix -> new([[1, 2, 3]]);\n\n");
$x = Math::Matrix -> new([[1, 2, 3]]);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[1, 2, 3]], '$x has the right values');

note("\n\$x = Math::Matrix -> new(3);\n\n");
$x = Math::Matrix -> new(3);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[ 3 ]], '$x has the right values');

note("\n\$x = Math::Matrix -> new([3]);\n\n");
$x = Math::Matrix -> new([3]);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[ 3 ]], '$x has the right values');

note("\n\$x = Math::Matrix -> new([[3]]);\n\n");
$x = Math::Matrix -> new([[3]]);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [[ 3 ]], '$x has the right values');

note("\n\$x = Math::Matrix -> new();\n\n");
$x = Math::Matrix -> new();
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [], '$x has the right values');

note("\n\$x = Math::Matrix -> new([]);\n\n");
$x = Math::Matrix -> new([]);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [], '$x has the right values');

note("\n\$x = Math::Matrix -> new([[]]);\n\n");
$x = Math::Matrix -> new([[]]);
is(ref($x), 'Math::Matrix', '$x is a Math::Matrix');
is_deeply([ @$x ], [], '$x has the right values');

###############################################################################

note("\n\$x -> new([1, 2, 3], [4, 5, 6]); \$y = \$x -> new([9, 8, 7], [6, 5, 4])\n\n");
$x = Math::Matrix -> new([1, 2, 3], [4, 5, 6]);
$y = $x -> new([9, 8, 7], [6, 5, 4]);
is_deeply([ @$x ], [[1, 2, 3], [4, 5, 6]], '$x is unmodified');
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
is_deeply([ @$y ], [[9, 8, 7], [6, 5, 4]], '$y has the right values');

note("\n\$x -> new([1, 2, 3], [4, 5, 6]); \$y = \$x -> new([9, 8, 7]);\n\n");
$x = Math::Matrix -> new([1, 2, 3], [4, 5, 6]);
$y = $x -> new([9, 8, 7]);
is_deeply([ @$x ], [[1, 2, 3], [4, 5, 6]], '$x is unmodified');
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
is_deeply([ @$y ], [[9, 8, 7]], '$y has the right values');

note("\n\$x -> new([1, 2, 3], [4, 5, 6]); \$y = \$x -> new(9);\n\n");
$x = Math::Matrix -> new([1, 2, 3], [4, 5, 6]);
$y = $x -> new(9);
is_deeply([ @$x ], [[1, 2, 3], [4, 5, 6]], '$x is unmodified');
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
is_deeply([ @$y ], [[9]], '$y has the right values');

###############################################################################

note("\n\$x = Math::Matrix -> new([1, 2, 3], [4, 5, 6]); \$y = \$x -> new();\n\n");
$x = Math::Matrix -> new([1, 2, 3], [4, 5, 6]);
$y = $x -> new();
is_deeply([ @$x ], [[1, 2, 3], [4, 5, 6]], '$x is unmodified');
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
is_deeply([ @$y ], [[0, 0, 0], [0, 0, 0]], '$y has the right values');

note("\n\$x = Math::Matrix -> new([1, 2, 3]); \$y = \$x -> new();\n\n");
$x = Math::Matrix -> new([1, 2, 3]);
$y = $x -> new();
is_deeply([ @$x ], [[1, 2, 3]], '$x is unmodified');
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
is_deeply([ @$y ], [[0, 0, 0]], '$y has the right values');

note("\n\$x = Math::Matrix -> new(1); \$y = \$x -> new();\n\n");
$x = Math::Matrix -> new(1);
$y = $x -> new();
is_deeply([ @$x ], [[1]], '$x is unmodified');
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
is_deeply([ @$y ], [[0]], '$y has the right values');

note("\n\$x = Math::Matrix -> new([]); \$y = \$x -> new();\n\n");
$x = Math::Matrix -> new([]);
$y = $x -> new();
is_deeply([ @$x ], [], '$x is unmodified');
is(ref($y), 'Math::Matrix', '$y is a Math::Matrix');
is_deeply([ @$y ], [], '$y has the right values');
