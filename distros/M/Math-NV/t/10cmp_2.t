use strict;
use warnings;
use Math::NV qw(:all);
use Test::More;

cmp_ok(cmp_2('+0b1111.01'  , '0xf.4'    ), '==', 0, 'test 1 ok');
cmp_ok(cmp_2('0b1111.01'  , '0x7.ap+01' ), '==', 0, 'test 2 ok');
cmp_ok(cmp_2('+0b111101e-2', '0x7ap-03' ), '==', 0, 'test 3 ok');

cmp_ok(cmp_2('-0b1111.01'  , '0xf.4'    ), '<',  0, 'test 4 ok');
cmp_ok(cmp_2('0b1111.01'  , '0x7.ap+01' ), '==', 0, 'test 5 ok');
cmp_ok(cmp_2('0b111101e-2', '-0x7ap-03' ), '>',  0, 'test 6 ok');

cmp_ok(cmp_2('0b1111.011', '0xf.4' ),      '>', 0,  'test 7 ok');
cmp_ok(cmp_2('+0b1111.011', '0x7.ap+01' ), '>', 0,  'test 8 ok');
cmp_ok(cmp_2('0b1111011e-2', '0x7ap-03' ), '>', 0,  'test 9 ok');

cmp_ok(cmp_2('0b1111.011', '-0xf.4' ),      '>', 0, 'test 10 ok');
cmp_ok(cmp_2('-0b1111.011', '0x7.ap+01' ),  '<', 0, 'test 11 ok');
cmp_ok(cmp_2('0b1111011e-2', '-0x7ap-03' ), '>', 0, 'test 12 ok');

cmp_ok(cmp_2('+0b1111.01', '0xf.5'      ), '<', 0,  'test 13 ok');
cmp_ok(cmp_2('0b1111.01', '0x7.bp+01'   ), '<', 0,  'test 14 ok');
cmp_ok(cmp_2('+0b111101e-2', '0x7bp-03 '), '<', 0,  'test 15 ok');

cmp_ok(cmp_2('-0b1111.01', '0xf.5'      ), '<', 0,  'test 16 ok');
cmp_ok(cmp_2('-0b1111.01', '0x7.bp+01'  ), '<', 0,  'test 17 ok');
cmp_ok(cmp_2('-0b111101e-2', '0x7bp-03 '), '<', 0,  'test 18 ok');

cmp_ok(cmp_2('0x1.6a09e667f3bcc908p+0', '0xb.504f333f9de6484p-3'), '==', 0, 'test 19 ok');
cmp_ok(cmp_2('0x1.6a09e667f3bcd', '0b0.10110101000001001111001100110011111110011101111001101p+1'),
       '==', 0, 'test 20 ok');

cmp_ok(cmp_2('0b0.10111101000000000000000000000000000000000000000000000E5', '0x1.7ap+4',),
       '==', 0, 'test 21 ok');
cmp_ok(cmp_2('0b0.10111101000000000000000000000000000000000000000000000E5', '0x1.7aP+4',),
       '==', 0, 'test 22 ok');
cmp_ok(cmp_2('0B0.10111101000000000000000000000000000000000000000000000E5', '0X1.7aP+4',),
       '==', 0, 'test 23 ok');
cmp_ok(cmp_2('0B0.10111101000000000000000000000000000000000000000000000e5', '0X1.7ap+4',),
       '==', 0, 'test 24 ok');

cmp_ok(cmp_2('+inf'  , 'INF'    ), '==', 0, 'inf == inf');
cmp_ok(cmp_2('-iNf'  , 'InF'    ), '<',  0, '-inf < inf');
cmp_ok(cmp_2('inF'  , '-INf'    ), '>',  0, 'inf > -inf');
cmp_ok(cmp_2('0x1p0'  , '-INf'  ), '>',  0, '1 > -inf'  );

cmp_ok(defined(cmp_2('+nan'   , '0x1p0'  )), '==', 0, 'cmp +nan is undef');

SKIP: {
  # In Math-MPFR-4.22 and earlier, if the first arg given to the spaceship operator is
  # a non-NaN value, and the second arg is a NaN value, then '0' is incorrectly
  # returned. The correct return is undef.

  skip "Math::MPFR bug (fixed in Math-MPFR-4.23)", 1 unless $Math::MPFR::VERSION > 4.22;
cmp_ok(defined(cmp_2('0x1p0' , '-nan'   )),  '==', 0, 'cmp -nan is undef');
}

cmp_ok(defined(cmp_2('nAN'    , '-0x1p0' )), '==', 0, 'cmp nan is undef' );

eval{cmp_2('0x1p0', '1');};
like($@, qr/^Invalid 2nd arg/, 'invalid second arg detected');

eval{cmp_2('1', '2');};
like($@, qr/^Invalid 1st arg/, 'invalid first arg detected' );

done_testing();
