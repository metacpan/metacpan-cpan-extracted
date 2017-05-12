#!perl -T

use Test::More tests => 9;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  var u = 1 >> 4;
  var v = 2 << 5;
  var w = 3 >>> 6;

  var a =1>>4;
  var b =2<<5;
  var c =3>>>6;
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-9: Check side-effects

is( $j->prop('u'), 0, 'u are 0' );
is( $j->prop('v'), 64, 'v is 64' );
is( $j->prop('w'), 0,  'w is 0'  );
is( $j->prop('a'), 0,  'a is 0'  );
is( $j->prop('b'), 64, 'b is 64' );
is( $j->prop('c'), 0, 'c is 0'  );
