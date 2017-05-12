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
  var t4 = 1 
  var t5a = 2 , t5b = 3 
  var t6=4;
  var t7a=5,t7b=6;

  var t8
  var t9;
  var t10a , t10b
  var t11a,t11b;
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-11: Check side-effects

is( $j->prop('t4'), 1,                           'var a = b'         );
ok( $j->prop('t5a') eq 2 && $j->prop('t5b') eq 3, 'var a = b , c = d' );
is( $j->prop('t6'), 4,                            'var a=b'           );
ok( $j->prop('t7a') eq 5 && $j->prop('t7b') eq 6, 'var a=b,c=d'      );
is( $j->prop('t8'), 'undefined',                  'var a'          );
is( $j->prop('t9'), 'undefined',                 'var a;'       );
ok( $j->prop('t10a') eq 'undefined' &&
    $j->prop('t10b') eq 'undefined',           'var a , b'  );
ok( $j->prop('t11a') eq 'undefined' &&
   $j->prop('t11b') eq 'undefined',         'var a , b' );
