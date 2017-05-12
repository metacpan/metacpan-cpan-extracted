#!perl -T

use Test::More tests => 7;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  t4 = ( 1 , 2 );
  t5 = (1,2);
  t6 = 3, t7 = 4
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-7: Check side-effects

is( $j->prop('t4'), 2, 'comma op with whitespace'   );
is( $j->prop('t5'), 2, 'comma op without whitespace' );
is( $j->prop('t6'), 3, 'comma precedence'            );
is( $j->prop('t7'), 4, 'comma precedence'           );
