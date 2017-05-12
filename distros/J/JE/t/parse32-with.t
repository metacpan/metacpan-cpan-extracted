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

  with ( {} ) t4 = toString()
  
  with({})t5 = toString()

--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-5: Check side-effects

is( $j->prop('t4'), '[object Object]', 'with ( a )' );
is( $j->prop('t5'), '[object Object]', 'with(a)'   );
