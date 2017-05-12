#!perl -T

use Test::More tests => 7;
use strict;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok(
my $code = $j->parse(q{
  var t4 = 1 | 2
  var t5 =1|2;

  for(t6 = 1  | 2 ;0;);
  for(t7=1|2;0;);
}),	'JE::Code');

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-7: Check side-effects

is( $j->prop('t4'), 3, 'a | b' );
is( $j->prop('t5'), 3, 'a|b'      );
is( $j->prop('t6'), 3, 'for(a | b;;)' );
is( $j->prop('t7'), 3, 'for(a|b;;)'      );
