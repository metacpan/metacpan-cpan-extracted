#!perl -T

use Test::More tests => 19;
use strict;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok(
my $code = $j->parse(q{
  var g
  var t10 = b( 1,2,b )
  var t11 = d( f,g,h )
  var t12= f( h )
  var t13 = h()
  var t14 = j( k())

  var t15 = b ( 1,2,b )
  var t16 = d ( f,g,h )
  var t17 = f ( h )
  var t18 = h ()
  var t19 = j ( k())
}),	'JE::Code');

#--------------------------------------------------------------------#
# Tests 3-8: Created necessary functions

my $sub = sub { ':' . join '-', @_ };

isa_ok( $j->new_function( b => $sub ), 'JE::Object::Function' );
isa_ok( $j->new_function( d => $sub ), 'JE::Object::Function' );
isa_ok( $j->new_function( f => $sub ), 'JE::Object::Function' );
isa_ok( $j->new_function( h => $sub ), 'JE::Object::Function' );
isa_ok( $j->new_function( j => $sub ), 'JE::Object::Function' );
isa_ok( $j->new_function( k => $sub ), 'JE::Object::Function' );

#--------------------------------------------------------------------#
# Test 9: Run code

$code->execute;
is($@, '', 'run code');

#--------------------------------------------------------------------#
# Tests 10-19: Check side-effects

my $f = qr/function /;
my $b = qr/\(\) \{[^}]+}/; # function body

like( $j->prop('t10'), qr/^:1-2-${f}b$b$/              );
like( $j->prop('t11'), qr/^:${f}f$b-undefined-${f}h$b$/ );
like( $j->prop('t12'), qr/^:${f}h$b$/                   );
is ( $j->prop('t13'), ':'                              );
is( $j->prop('t14'), '::'                              );
like( $j->prop('t15'), qr/^:1-2-${f}b$b$/              );
like( $j->prop('t16'), qr/^:${f}f$b-undefined-${f}h$b$/ );
like( $j->prop('t17'), qr/^:${f}h$b$/                   );
is ( $j->prop('t18'), ':'                              );
is( $j->prop('t19'), '::'                            );
