#!perl -T

use Test::More tests => 5;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');

  while ( 1 ) { t4 = 4; break }
  
  while(1){ t5 = 4; break }

--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-5: Check side-effects

is( $j->prop('t4'), 4, 'while ( a )' );
is( $j->prop('t5'), 4, 'while(a)'   );
