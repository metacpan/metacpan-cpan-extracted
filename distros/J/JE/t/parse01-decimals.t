#!perl -T

use Test::More tests => 59;
use strict;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  a = 0;
  b = 1;
  c = 2;
  d = 3;
  e = 4;
  f = 5;
  g = 6;
  h = 7;
  i = 8;
  j = 9;

/* Maybe I could optimize this later by turning these into decimal lit-
  erals. Right now they are each a prefix op followed by a literal.
  k = +0;
  l = +1;
  m = +2;
  n = +3;
  o = +4;
  p = +5;
  q = +6;
  r = +7;
  s = +8;
  t = +9;
  u = -0;
  v = -1;
  w = -2;
  x = -3;
  y = -4;
  z = -5;
  A = -6;
  B = -7;
  C = -8;
  D = -9;
*/
  E = 10;
  F = 100;
  G = 1000;
  H = 10.5;
  H1 = 10.
  I  = 0.7;
  I1 = 0.
  J = .6;
  K = .6E6;
  L = .6E-6;
  M = .6E+6;
  N = .6e6;
  O = .6e-6;
  P = .6e+6;
  Q = 0E0;
  R = 10E0;

  S = 13e2
  T = 13.e2
  U = 13.0e2
  V = 13e+2
  W = 13.e+2
  X = 13.0e+2
  Y = 13e-2
  Z = 13.e-2
  $ = 13.0e-2
  _ = 13E2
  a1 = 13.E2
  a2 = 13.0E2
  a3 = 13E+2
  a4 = 13.E+2
  a5 = 13.0E+2
  a6 = 13E-2
  a7 = 13.E-2
  a8 = 13.0E-2

  a9 = 0.4e3
  a0 = 0.4e+3
  aa = 0.4e-3
  ab = 0.4E3
  ac = 0.4E+3
  ad = 0.4E-3

  ae = 0.e3
  af = 0.e+3
  ag = 0.e-3
  ah = 0.E3
  ai = 0.E+3
  aj = 0.E-3
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-59: Check side-effects

is( $j->prop('a'), 0, 'digit 0' );
is( $j->prop('b'), 1, 'digit 1' );
is( $j->prop('c'), 2, 'digit 2' );
is( $j->prop('d'), 3, 'digit 3' );
is( $j->prop('e'), 4, 'digit 4' );
is( $j->prop('f'), 5, 'digit 5' );
is( $j->prop('g'), 6, 'digit 6' );
is( $j->prop('h'), 7, 'digit 7'  );
is( $j->prop('i'), 8, 'digit 8'    );
is( $j->prop('j'), 9, 'digit 9'       );
is( $j->prop('E'), 10, 'multiple digits' );
is( $j->prop('F'), 100, 'multiple digits'  );
is( $j->prop('G'), 1000, 'multiple digits'  );
is( $j->prop('H'), 10.5, 'decimal point'      );
is( $j->prop('H1'), 10, 'trailing decimal point' );
is( $j->prop('I'),  .7, '"0." followed by digit'   );
is( $j->prop('I1'), 0, '"0."'                        );
is( $j->prop('J'), .6, 'leading decimal point'         );
is( $j->prop('K'), 6e5, 'leading decimal point + E digit' );
is( $j->prop('L'), 6e-7, 'leading decimal point + E-digit'  );
is( $j->prop('M'), 6e5,  'leading decimal point + E+digit'   );
is( $j->prop('N'), 6e5,  'leading decimal point + e digit'   );
is( $j->prop('O'), 6e-7, 'leading decimal point + e-digit'  );
is( $j->prop('P'), 6e5,  'leading decimal point + e+digit' );
is( $j->prop('Q'), 0,   'integer with E'                   );
is( $j->prop('R'), 10,  'integer with E'                    );
is( $j->prop('S'), 1300, 'integer with e digit'              );
is( $j->prop('T'), 1300, 'trailing decimal point with e digit' );
is( $j->prop('U'), 1300, 'decimal point with e digit'           );
is( $j->prop('V'), 1300, 'integer with e+digit'                 );
is( $j->prop('W'), 1300, 'trailing decimal point with e+digit' );
is( $j->prop('X'), 1300, 'decimal point with e+digit'         );
is( $j->prop('Y'), .13, 'integer with e-digit'                );
is( $j->prop('Z'), .13, 'trailing decimal point with e-digit' );
is( $j->prop('$'), .13, 'decimal point with e-digit'          );
is( $j->prop('_'), 1300, 'integer with E digit'                );
is( $j->prop('a1'), 1300, 'trailing decimal point with E digit' );
is( $j->prop('a2'), 1300, 'decimal point with E digit'          );
is( $j->prop('a3'), 1300, 'integer with E+digit'                );
is( $j->prop('a4'), 1300, 'trailing decimal point with E+digit' );
is( $j->prop('a5'), 1300, 'decimal point with E+digit'         );
is( $j->prop('a6'), .13, 'integer with E-digit'                );
is( $j->prop('a7'), .13, 'trailing decimal point with E-digit' );
is( $j->prop('a8'), .13, 'decimal point with E-digit'         );
is( $j->prop('a9'), 400, '0.digit with e digit'             );
is( $j->prop('a0'), 400,  '0.digit with e+digit'         );
is( $j->prop('aa'), .0004, '0.digit with e-digit'     );
is( $j->prop('ab'), 400,   '0.digit with E digit'   );
is( $j->prop('ac'), 400,   '0.digit with E+digit'  );
is( $j->prop('ad'), .0004, '0.digit with E-digit' );
is( $j->prop('ae'), 0,    '0. with e digit'     );
is( $j->prop('af'), 0,  '0. with e+digit'    );
is( $j->prop('ag'), 0, '0. with e-digit'   );
is( $j->prop('ah'), 0, '0. with E digit'  );
is( $j->prop('ai'), 0, '0. with E+digit' );
is( $j->prop('aj'), 0, '0. with E-digit' );
