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
  t4 = 7 * 8
  t5 = 1 / 2
  t6 = 1 % 2

  t7 =7*8;
  t8 =1/2;
  t9 =1%2;
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-9: Check side-effects

is( $j->prop('t4'), 56 );
is( $j->prop('t5'), .5 );
is( $j->prop('t6'), 1  );
is( $j->prop('t7'), 56 );
is( $j->prop('t8'), .5 );
is( $j->prop('t9'), 1 );
