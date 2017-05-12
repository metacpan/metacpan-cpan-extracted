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
  var a=   ['yan','tan','tether','hether'];

  var t4 = a[0]
  t5 = a [ 1 ] 
  t6
   =
    a
     [
      2
       ]

  b = { yan: 1,
        tan:  2,
        tether: 3,
        hether:  4
      }

  t7 = b.yan
  t8 = b . tan 
  t9
   =
    b
     .
      tether
       undefined  // this line is its own statement
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-9: Check side-effects

is( $j->prop('t4'), 'yan' );
is( $j->prop('t5'), 'tan'  );
is( $j->prop('t6'), 'tether' );
is( $j->prop('t7'), 1         );
is( $j->prop('t8'), 2         );
is( $j->prop('t9'), 3        );
