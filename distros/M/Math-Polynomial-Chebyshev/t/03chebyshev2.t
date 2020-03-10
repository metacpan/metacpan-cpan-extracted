#!perl

use strict;                     # Import test functions
use warnings;

use Test::More tests => 41;

use Math::Polynomial::Chebyshev2;

my $coef =
  [
   [ 1 ],
   [ 0, 2 ],
   [ -1, 0, 4 ],
   [ 0, -4, 0, 8 ],
   [ 1, 0, -12, 0, 16 ],
   [ 0, 6, 0, -32, 0, 32 ],
   [ -1, 0, 24, 0, -80, 0, 64 ],
   [ 0, -8, 0, 80, 0, -192, 0, 128 ],
   [ 1, 0, -40, 0, 240, 0, -448, 0, 256 ],
   [ 0, 10, 0, -160, 0, 672, 0, -1024, 0, 512 ],
  ];

my $root =
  [
   [

   ],

   [
    0e+1
   ],

   [
    -5e-1,
    5e-1
   ],

   [
    -7.071067811865475e-1,
    0e+1,
    7.071067811865475e-1
   ],

   [
    -8.090169943749474e-1,
    -3.090169943749474e-1,
    3.090169943749474e-1,
    8.090169943749474e-1
   ],

   [
    -8.660254037844386e-1,
    -5e-1,
    0e+1,
    5e-1,
    8.660254037844386e-1
   ],

   [
    -9.009688679024191e-1,
    -6.234898018587335e-1,
    -2.225209339563144e-1,
    2.225209339563144e-1,
    6.234898018587335e-1,
    9.009688679024191e-1
   ],

   [
    -9.238795325112868e-1,
    -7.071067811865475e-1,
    -3.826834323650898e-1,
    0e+1,
    3.826834323650898e-1,
    7.071067811865475e-1,
    9.238795325112868e-1
   ],

   [
    -9.396926207859084e-1,
    -7.660444431189780e-1,
    -5e-1,
    -1.736481776669303e-1,
    1.736481776669303e-1,
    5e-1,
    7.660444431189780e-1,
    9.396926207859084e-1
   ],

   [
    -9.510565162951536e-1,
    -8.090169943749474e-1,
    -5.877852522924731e-1,
    -3.090169943749474e-1,
    0e+1,
    3.090169943749474e-1,
    5.877852522924731e-1,
    8.090169943749474e-1,
    9.510565162951536e-1
   ],

  ];

isa_ok('Math::Polynomial::Chebyshev2', 'Math::Polynomial');

for (my $i = 0 ; $i <= $#$coef ; ++$i) {
    my $p = Math::Polynomial::Chebyshev2 -> chebyshev2($i);

    isa_ok($p, 'Math::Polynomial::Chebyshev2');
    isa_ok($p, 'Math::Polynomial');

    my $coef_got = [ $p -> coefficients() ];
    my $coef_expected = $coef -> [$i];

    subtest "coefficients of U($i)" => sub {
        plan tests => 1 + @$coef_expected;

        cmp_ok(scalar(@$coef_got), '==', scalar(@$coef_expected));
        for (my $j = 0 ; $j <= $#$coef_expected ; ++$j) {
            my $diff = abs($coef_got -> [$j] - $coef_expected -> [$j]);
            cmp_ok($diff, '<=', 1e-15, "coefficient $j");
        }
    };

    my $root_got = [ $p -> roots() ];
    my $root_expected = $root -> [$i];

    subtest "roots of U($i)" => sub {
        plan tests => 1 + @$root_expected;

        cmp_ok(scalar(@$root_got), '==', scalar(@$root_expected));
        for (my $j = 0 ; $j <= $#$root_expected ; ++$j) {
            my $diff = abs($root_got -> [$j] - $root_expected -> [$j]);
            cmp_ok($diff, '<=', 1e-15, "root $j");
        }
    };
}
