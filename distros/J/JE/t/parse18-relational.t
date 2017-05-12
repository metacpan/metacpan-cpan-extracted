#!perl -T

use Test::More tests => 25;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  var a = 1 < 2;
  var b = 3 > 4;
  var c = 5 >= 6;
  var d = 7 <= 8;
  var e = 9 instanceof Function;
  var f = 11 in {};

  var a1 =1<2;
  var b1 =3>4;
  var c1 =5>=6;
  var d1 =7<=8;
  var e1 =(9)instanceof(Object);
  var f1 =(11)in{12:13};

  for(var a2 = 1 < 2;0;);
  for(var b2 = 3 > 4;0;);
  for(var c2 = 5 >= 6;0;);
  for(var d2 = 7 <= 8;0;);
  for(var e2 = 9 instanceof Function;0;);

  for(var a3 =1<2;0;);
  for(var b3 =3>4;0;);
  for(var c3 =5>=6;0;);
  for(var d3 =7<=8;0;);
  for(var e3 =(9)instanceof(Object);0;);
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-25: Check side-effects

is( $j->prop('a'), 'true', 'a < b' );
is( $j->prop('b'), 'false', 'a > b' );
is( $j->prop('c'), 'false', 'a >= b'  );
is( $j->prop('d'), 'true',  'a <= b'     );
is( $j->prop('e'), 'false', 'a instanceof b' );
is( $j->prop('f'), 'false', 'a in b'            );
is( $j->prop('a1'), 'true', 'a<b'                 );
is( $j->prop('b1'), 'false', 'a>b'                 );
is( $j->prop('c1'), 'false', 'a>=b'                );
is( $j->prop('d1'), 'true',  'o<=b'               );
is( $j->prop('e1'), 'false', '(a)instanceof(b)' );
is( $j->prop('f1'), 'false', '(a)in{b:c}'      );
is( $j->prop('a2'), 'true',  'for(a < b;;)'    );
is( $j->prop('b2'), 'false', 'for(a > b;;)'    );
is( $j->prop('c2'), 'false', 'for(a >= b;;)'    );
is( $j->prop('d2'), 'true',  'for(a <= b;;)'      );
is( $j->prop('e2'), 'false', 'for(a instanceof b;;)' );
is( $j->prop('a3'), 'true',  'for(a<b;;)'              );
is( $j->prop('b3'), 'false', 'for(a>b;;)'               );
is( $j->prop('c3'), 'false', 'for(a>=b;;)'              );
is( $j->prop('d3'), 'true',  'for(a<=b;;)'             );
is( $j->prop('e3'), 'false', 'for((a)instanceof(b);;)' );
