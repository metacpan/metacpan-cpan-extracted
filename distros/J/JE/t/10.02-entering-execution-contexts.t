#!perl -T

# WARNING: This is a brilliant example of how not to write code. (Though
# I must admit that the sextuple backslash was fun.)


BEGIN { require './t/test.pl' }

use Test::More tests => 30;
use Scalar::Util 'refaddr';
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );

# Test 4: Bind Perl's eval to JS so we can do naughty stuff.
isa_ok( $j->new_function( peval => sub { eval shift } ),
	'JE::Object::Function' );


# Run JS tests

defined $j->eval( <<'--end--' ) or die;

// ---------------------------------------------------
/* Tests 5-9: global code */

// These line breaks would cause a syntax error according to spec.
// JE supports line breaks in string literals. Don't tell anyone.
peval('
	my @scope = @$JE::Code::scope; # Don\'t do this at 
	                                           # home--I mean in pro-
	                                         # duction  code!  These
	                                      # internal details are sub-
	                                  # ject to change.
	ok @scope == 1, "scope chain in global code contains one object";
	ok refaddr $scope[0] == refaddr $j,
		"that object is the global object";
');

var thing;
ok(this.hasOwnProperty('thing'), 'global object is the variable object')
ok(!delete thing, 'vars declared in global code are undeletable')

peval('ok refaddr shift @_ == refaddr $j,
	"the \'this\' value is the global object"', this)


// ---------------------------------------------------
/* Tests 10-17: function code */

var obj = Object();
with(obj) {
	obj.f = function(){
		peval('
			my @scope = @$JE::Code::scope;
			my @fscope = @{$${$j->eval("obj.f")->get}{scope}};
			ok @scope  == 3, q/@scope == 3/;
			ok @fscope == 2, q/@fscope == 2/;
			ok refaddr $scope[0] == refaddr $fscope[0] &&
			   refaddr $scope[0] == refaddr $j,
				"first object in function\'s scope chain" .
				" is the global obj";
			ok refaddr $scope[1] == refaddr $fscope[1] &&
			   refaddr $scope[1] == refaddr $j->prop("obj"),
				"\'with\' object in scope chain";
			ok ref $scope[2] eq \'JE::Object::Function::Call\',
				"\\\$scope has a call object";
		');

		var thing;
		ok(peval('exists $JE::Code::scope->[-1]{thing}
			'), "activation object is the variable object")
		ok(!delete thing,
			'vars declared in function code are undeletable')
		ok(this === obj, '"this" value in function code')
	}
}
obj.f()


// ---------------------------------------------------
/* Tests 18-22: 'global-eval code' (eval code called from global code) */

eval("

peval('
	my @scope = @$JE::Code::scope;
	ok @scope == 1,
		\"scope chain in global-eval code contains one object\";
	ok refaddr $scope[0] == refaddr $j,
		\"object in global-eval scope chain is the global object\";
');

var thing2;
ok(this.hasOwnProperty('thing2'),
	'global object is the variable object in global-eval code')
ok(delete thing2, 'vars declared in global-eval code are deletable')

peval('ok refaddr shift(@_) == refaddr $j,
	\"the \\'this\\' value in global-eval code is the global object\"', this)
")

// ---------------------------------------------------
/* Tests 23-30: function-eval code */

var obj2 = Object();
with(obj2) {
	obj2.f = function(){
		eval("

		peval('
			my @scope = @$JE::Code::scope;
			my @fscope =
				@{$${$j->eval(\"obj2.f\")->get}{scope}};
			ok @scope  == 3, q/@scope == 3 (function-eval)/;
			ok @fscope == 2, q/@fscope == 2 (function-eval)/;
			ok refaddr $scope[0] == refaddr $fscope[0] &&
			   refaddr $scope[0] == refaddr $j,
			       \"first object in function\\'s scope \" .
			       \" chain is the global obj (in eval code)\";
			ok refaddr $scope[1] == refaddr $fscope[1] &&
			   refaddr $scope[1] == refaddr $j->prop(\"obj2\"),
				\"\\'with\\' object in function-eval \" .
				\"scope chain\";
			ok ref $scope[2] eq
				\\'JE::Object::Function::Call\\',
				\"\\\\\\$scope has a call object\";
		');

		var thing;
		ok(peval('exists $JE::Code::scope->[-1]{thing}
			'), \"activation object is the variable object \" +
			    \"in function-eval code\")
		ok(delete thing,
		    'vars declared in function-eval code are deletable')
		ok(this === obj2, '\"this\" value in function-eval code')

		") // end of eval
	}
}
obj2.f()


--end--
