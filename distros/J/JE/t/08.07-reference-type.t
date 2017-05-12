#!perl -T

# Tests lvalues (aka 'references')

BEGIN { require './t/test.pl' }

use Test::More tests => 9;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );


# Run JS tests

defined $j->eval( <<'--end--' ) or die;

// ---------------------------------------------------
/* Tests 4-6: GetValue() */

ok(3===3, 'GetValue(V) when V is not a reference')

var is_ReferenceError;
try { nonexistent_var }
catch (e) {
	e instanceof ReferenceError && (is_ReferenceError = true)
}
ok(is_ReferenceError,
	'GetValue(V) when V\'s base is null throws a ReferenceError')

ok(this.nonexistent_var === undefined,
	'GetValue(V) when V\'s base is is not null')


// ---------------------------------------------------
/* Tests 7-9: PutValue() */

is_ReferenceError = false;
try { 3 = 4 }
catch(e) {
	e instanceof ReferenceError && ++ is_ReferenceError
}
ok(is_ReferenceError, 'PutValue(V,W) when V is not an lvalue')

nonexistent = 3
ok('nonexistent' in this && nonexistent == 3 ,
	'PutValue(V,W) when base of V is null')

this.undefined = 17
ok(undefined == 17, 'PutValue(V,W) when V is object')



--end--
