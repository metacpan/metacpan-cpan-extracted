#!perl -T

# Test left-hand-side expressions

use Test::More tests => 21;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  t4 = new new Function
  t5 = new new Function ()
  t6 = new new Function ()()

  t7 = new Object
  t8 = new function(){}
  t9 = new(Object)
  t10 = new (Object)
  t11 = new this.Object

  t12 = new Object()
  t13 = new function(){}()
  t14 = new(Object)()
  t15 = new (Object)()
  t16 = new this.Object()

  t17 = Object.prototype
  t18 = Object()
  t19 = new function(){}().constructor()
  t20 = new function(){}().constructor.prototype
  t21 = new new new new Object().constructor()['cons' + "tructor"]()
   .constructor().htns
--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-21: Check side-effects

is( $j->prop('t4'), '[object Object]' );
is( $j->prop('t5'), '[object Object]' );
is( $j->prop('t6'), '[object Object]' );
is( $j->prop('t7'), '[object Object]' );
is( $j->prop('t8'), '[object Object]' );
is( $j->prop('t9'), '[object Object]' );
is( $j->prop('t10'), '[object Object]' );
is( $j->prop('t11'), '[object Object]' );
is( $j->prop('t12'), '[object Object]' );
is( $j->prop('t13'), '[object Object]' );
is( $j->prop('t14'), '[object Object]' );
is( $j->prop('t15'), '[object Object]' );
is( $j->prop('t16'), '[object Object]' );
is( $j->prop('t17'), '[object Object]' );
is( $j->prop('t18'), '[object Object]' );
is( $j->prop('t19'), 'undefined'       );
is( $j->prop('t20'), '[object Object]' );
is( $j->prop('t21'), 'undefined'      );
