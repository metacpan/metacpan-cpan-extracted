#!perl -T

use Test::More tests => 15;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code') or diag $@;
  bar = '?';

  var t5 = { };
  var t6 = { foo   : bar };
  var t7 = {   1   : 2+2 };
  var t8 = { 'baz' : f() };
  var t9 = { "baz" : 3 , "bar" : 4 };

  t10 = {}
  t11 = {foo:bar};
  t12 = {1:2+2}
  t13 = {'baz':f()}
  t14 = {"baz":3,"bar":4}
  t15 = { foo: 123, };
--end--

#--------------------------------------------------------------------#
# Test 3: Created necessary function

isa_ok( $j->new_function( f => sub { 'oo' } ), 'JE::Object::Function' );

#--------------------------------------------------------------------#
# Test 4: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 5-14: Check side-effects

sub joyne ($) {
	my $tmp = $j->prop(shift);
	join '-', map +($_ => $tmp->prop($_)), $tmp->keys;
		# keys produces the property names in the order in which
		# they were inserted
}

is( joyne 't5', ''     );
is( joyne 't6', 'foo-?' );
is( joyne 't7', '1-4'    );
is( joyne 't8', 'baz-oo'   );
is( joyne 't9', 'baz-3-bar-4' );
is( joyne 't10', ''             );
is( joyne 't11', 'foo-?'         );
is( joyne 't12', '1-4'           );
is( joyne 't13', 'baz-oo'       );
is( joyne 't14', 'baz-3-bar-4' );
is( joyne 't15', 'foo-123'   );
