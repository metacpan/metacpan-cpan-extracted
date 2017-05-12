#!perl -T

use Test::More tests => 11;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  var t4 = 1 && 2
  t5 = 1 || 2
  t6 =1&&2;
  t7=1||2;

  for(t8 = 1 && 2 ;0;);
  for(t9 = 1 || 2 ;0;);
  for(t10 =1&&2;0;);
  for(t11 =1||2;0;);
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-11: Check side-effects

is( $j->prop('t4'), 2, 't4 is 2' );
is( $j->prop('t5'), 1, 't5 is 1' );
is( $j->prop('t6'), 2, 't6 is 2' );
is( $j->prop('t7'), 1, 't7 is 1' );
is( $j->prop('t8'), 2, 't8 is 2' );
is( $j->prop('t9'), 1, 't9 is 1'  );
is( $j->prop('t10'), 2, 't10 is 2' );
is( $j->prop('t11'), 1, 't11 is 1' );
