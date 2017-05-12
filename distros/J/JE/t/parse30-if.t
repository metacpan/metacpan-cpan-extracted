#!perl -T

use Test::More tests => 8;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');

if ( 1 ) t4a = 4; else ;
if ( 0 ) ; else t4b = 5

if(1)t5a = 4;else;
if(0);else(t5b = 5)

if ( 1 ) t6 = 6
if ( 0 ) t6 = 7

if(1)t7 = 6
if(0)t7 = 7

if (7)
  if (8)
    t8 = 8
  else t8 = 9
else t8 = 10

--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-8: Check side-effects

ok( $j->prop('t4a') eq 4 && $j->prop('t4b') eq 5, 'if-else' );
ok( $j->prop('t5a') eq 4 &&
   $j->prop('t5b') eq 5, 'if-else (minimal white space)'    );
is( $j->prop('t6'), 6,  'if without else'                    );
is( $j->prop('t7'), 6, 'if without else (minimal white space)' );
is( $j->prop('t8'), 8, 'nested if'                              );
