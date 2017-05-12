#!perl -T

use Test::More tests => 17;
use strict;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok(
my $code = $j->parse(q{
  var a = [ ]
  var a1 = [ , ]
  var a2 = [ ,,,, ,,,, ]
  var b = [ 1, 2, 3 ]
  var b1 = [ 1+4, 2, 3 ]
  var b2 = [ 1, 2+5, 3 ]
  var b3 = [ 1, 2, 3+f() ]
  var c = [ a, b ]
  var d = [ [ a ], [ a, b ] ]
}),	'JE::Code');

#--------------------------------------------------------------------#
# Test 3: Created necessary function

my $sub = sub { ':' . join '-', @_ };

isa_ok( $j->new_function( f => $sub ), 'JE::Object::Function' );

#--------------------------------------------------------------------#
# Test 4: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 5-17: Check side-effects

is( $j->prop('a'), '' );
is( $j->prop('a1'), ''    );
is( $j->prop('a2'), ',,,,,,,' );
is( $j->prop('b'),  '1,2,3'      );
is( $j->prop('b1'), '5,2,3'        );
is( $j->prop('b2'), '1,7,3'         );
is( $j->prop('b3'), '1,2,3:'        );
is( $j->prop('c'), ',1,2,3'        );
is( $j->prop('d'), ',,1,2,3'      );
is( scalar @{ $j->prop('a') }, 0  );
is( scalar @{ $j->prop('a1') }, 1 );
is( scalar @{ $j->prop('a2') }, 8 );
is( scalar @{ $j->prop('d') }, 2 );
