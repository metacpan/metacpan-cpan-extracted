#!perl -T

use Test::More tests => 23;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  var a = 1 == 2;
  var b = 3 != 4;
  var c = 5 === 6;
  var d = 7 !== 8;
  var e = 9 < 10 == 11;

  var a1 =1==2;
  var b1 =3!=4;
  var c1 =5===6;
  var d1 =7!==8;
  var e1 =9<10==11;

  for(a2 = 1 == 2;0;);
  for(b2 = 3 != 4;0;);
  for(c2 = 5 === 6;0;);
  for(d2 = 7 !== 8;0;);
  for(e2 = 9 < 10 == 11;0;);

  for(a3 =1==2;0;);
  for(b3 =3!=4;0;);
  for(c3 =5===6;0;);
  for(d3 =7!==8;0;);
  for(e3 =9<10==11;0;);
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-23: Check side-effects

is( $j->prop('a'), 'false', 'a == b' );
is( $j->prop('b'), 'true',  'a != b' );
is( $j->prop('c'), 'false', 'a === b' );
is( $j->prop('d'), 'true',  'a !== b'  );
is( $j->prop('e'), 'false', 'a < b == c' );
is( $j->prop('a1'), 'false', 'a==b'       );
is( $j->prop('b1'), 'true',  'a!=b'       );
is( $j->prop('c1'), 'false', 'a===b'      );
is( $j->prop('d1'), 'true',  'a!==b'      );
is( $j->prop('e1'), 'false', 'a<b==c'      );
is( $j->prop('a2'), 'false', 'for(a == b;;)' );
is( $j->prop('b2'), 'true',  'for(a != b;;)'  );
is( $j->prop('c2'), 'false', 'for(a === b;;)' );
is( $j->prop('d2'), 'true',  'for(a !== b;;)'  );
is( $j->prop('e2'), 'false', 'for(a < b == c;;)' );
is( $j->prop('a3'), 'false', 'for(a==b;;)'        );
is( $j->prop('b3'), 'true',  'for(a!=b;;)'        );
is( $j->prop('c3'), 'false', 'for(a===b;;)'      );
is( $j->prop('d3'), 'true',  'for(a!==b;;)'    );
is( $j->prop('e3'), 'false', 'for(a<b==c;;)' );
