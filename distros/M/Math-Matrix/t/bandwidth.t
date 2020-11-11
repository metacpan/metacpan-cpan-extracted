#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 27;

my $x;
my ($n, $l, $u);

################################

note(<<'EOF');
[[0]]
EOF

$x = Math::Matrix -> new([[0]]);
$n = $x -> bandwidth();
cmp_ok($n, '==', 0);
($l, $u) = $x -> bandwidth();
cmp_ok($l, '==', 0);
cmp_ok($u, '==', 0);

################################

note(<<'EOF');
[[1]]
EOF

$x = Math::Matrix -> new([[1]]);
$n = $x -> bandwidth();
cmp_ok($n, '==', 0);
($l, $u) = $x -> bandwidth();
cmp_ok($l, '==', 0);
cmp_ok($u, '==', 0);

################################

note(<<'EOF');
[[1, 0],
 [0, 2]]
EOF

$x = Math::Matrix -> new([[1, 0],
                          [0, 2]]);
$n = $x -> bandwidth();
cmp_ok($n, '==', 0);
($l, $u) = $x -> bandwidth();
cmp_ok($l, '==', 0);
cmp_ok($u, '==', 0);

################################

note(<<'EOF');
[[1, 3],
 [4, 2]]
EOF

$x = Math::Matrix -> new([[1, 3],
                          [4, 2]]);
$n = $x -> bandwidth();
cmp_ok($n, '==', 1);
($l, $u) = $x -> bandwidth();
cmp_ok($l, '==', 1);
cmp_ok($u, '==', 1);

################################

note(<<'EOF');
[[1, 3, 0],
 [4, 2, 5],
 [0, 6, 7]]
EOF

$x = Math::Matrix -> new([[1, 3, 0],
                          [4, 2, 5],
                          [0, 6, 7]]);
$n = $x -> bandwidth();
cmp_ok($n, '==', 1);
($l, $u) = $x -> bandwidth();
cmp_ok($l, '==', 1);
cmp_ok($u, '==', 1);

################################

note(<<'EOF');
[[1, 3, 8],
 [4, 2, 5],
 [9, 6, 7]]
EOF

$x = Math::Matrix -> new([[1, 3, 8],
                          [4, 2, 5],
                          [9, 6, 7]]);
$n = $x -> bandwidth();
cmp_ok($n, '==', 2);
($l, $u) = $x -> bandwidth();
cmp_ok($l, '==', 2);
cmp_ok($u, '==', 2);

################################

note(<<'EOF');
[[1, 3, 8, 0],
 [4, 2, 5, 2],
 [9, 6, 7, 1],
 [0, 3, 5, 4]]
EOF

$x = Math::Matrix -> new([[1, 3, 8, 0],
                          [4, 2, 5, 2],
                          [9, 6, 7, 1],
                          [0, 3, 5, 4]]);
$n = $x -> bandwidth();
cmp_ok($n, '==', 2);
($l, $u) = $x -> bandwidth();
cmp_ok($l, '==', 2);
cmp_ok($u, '==', 2);

################################

note(<<'EOF');
[[1, 3, 8, 9],
 [4, 2, 5, 2],
 [9, 6, 7, 1],
 [2, 3, 5, 4]]
EOF

$x = Math::Matrix -> new([[1, 3, 8, 9],
                          [4, 2, 5, 2],
                          [9, 6, 7, 1],
                          [2, 3, 5, 4]]);
$n = $x -> bandwidth();
cmp_ok($n, '==', 3);
($l, $u) = $x -> bandwidth();
cmp_ok($l, '==', 3);
cmp_ok($u, '==', 3);

################################

note(<<'EOF');
[[3, 3, 3, 0, 0, 0],
 [3, 3, 3, 3, 0, 0],
 [0, 3, 3, 3, 3, 0],
 [0, 0, 3, 3, 3, 3],
 [0, 0, 0, 3, 3, 3],
 [0, 0, 0, 0, 3, 3]]
EOF

$x = Math::Matrix -> new([[3, 3, 3, 0, 0, 0],
                          [3, 3, 3, 3, 0, 0],
                          [0, 3, 3, 3, 3, 0],
                          [0, 0, 3, 3, 3, 3],
                          [0, 0, 0, 3, 3, 3],
                          [0, 0, 0, 0, 3, 3]]);
$n = $x -> bandwidth();
cmp_ok($n, '==', 2);
($l, $u) = $x -> bandwidth();
cmp_ok($l, '==', 1);
cmp_ok($u, '==', 2);
