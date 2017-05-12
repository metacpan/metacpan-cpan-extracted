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
  var u = 7 + 8
  var v = 1 - 2
  var w = 5 -+6
  var x = 3+4
}),	'JE::Code');

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-7: Check side-effects

is( $j->prop('u'), 15, 'u is 15' );
is( $j->prop('v'), -1, 'v is -1' );
is( $j->prop('w'), -1, 'w is -1' );
is( $j->prop('x'), 7, 'x is 7'  );
