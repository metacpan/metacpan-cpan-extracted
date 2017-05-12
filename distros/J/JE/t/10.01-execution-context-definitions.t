#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 116;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );

# We need some readonly global variables to play with
$j->prop({ name => readonly  => readonly => 1 }); 
$j->prop({ name => readonly2 => readonly => 1 }); 
$j->prop({ name => readonly3 => readonly => 1 }); 

# Run JS tests

defined $j->eval( <<'--end--' ) or die;

// ===================================================
// 10.1.3 Variable Instantiation
// ===================================================

// ---------------------------------------------------
/* Tests 4-71: var and function declarations */

ok('function1'  in this, 'function declarations in global code')
ok('variable'   in this, 'var declarations in global code')
ok('function2'  in this, 'function declarations in blocks in global code')
ok('var2'       in this, 'var declarations in blocks in global code')
ok('var3'       in this, 'var declaration within for(;;) header')
ok('var4'       in this, 'var declaration within for-in header')
ok('if_func'    in this, 'if() { function ... } in global code')
ok('if_var'     in this, 'if() { var ... } in global code')
ok('else_func'  in this, 'else { function ... } in global code')
ok('else_var'   in this, 'else { var ... } in global code')
ok('do_func'    in this, 'do { function ... } in global code')
ok('do_var'     in this, 'do { var ... } in global code')
ok('while_func' in this, 'while() { function ... } in global code')
ok('while_var'  in this, 'while() { var ... } in global code')
ok('for_func'   in this, 'for(;;) { function ... } in global code')
ok('for_var'    in this, 'for(;;) { var ... } in global code')
ok('for_in_func'in this, 'for(... in ...) { function ... } in global code')
ok('for_in_var' in this, 'for(... in ...) { var ... } in global code')
ok('with_func'  in this, 'with() { function ... } in global code')
ok('with_var'   in this, 'with() { var ... } in global code')
ok('case_func'  in this, 'case: function... in global code')
ok('case_var'    in this, 'case: var... in global code')
ok('default_func' in this, 'default: function... in global code')
ok('default_var'  in this, 'default: var... in global code')
ok('case2_func'   in this, 'default: case: function... in global code')
ok('case2_var'    in this, 'default: case: var... in global code')
ok('label_func'   in this, 'label: { function... } in global code')
ok('label_var'    in this, 'label: var... in global code')
ok('try_func'     in this, 'try { function... } in global code')
ok('try_var'      in this, 'try { var... } in global code')
ok('catch_func'   in this, 'catch() { function... } in global code')
ok('catch_var'    in this, 'catch() { var... } in global code')
ok('finally_func' in this, 'finally { function... } in global code')
ok('finally_var'  in this, 'finally { var... } in global code')

function function1 () { } // declaration, not expr
var variable
{
	function function2(){} var var2
}

if(0){ function if_func  (){} var if_var   }
else { function else_func(){} var else_var }

do { function do_func(){} var do_var } while(0);
while(0){ function while_func(){} var while_var }

for(var var3; 0;)    { function for_func   (){} var for_var    }
for(var var4 in this){ function for_in_func(){} var for_in_var }

with(ok) { function with_func(){} var with_var }

switch(38){
	case 2:  function case_func   (){} var case_var
	default: function default_func(){} var default_var
	case 3:  function case2_func  (){} var case2_var
}

labelled_statement: { function label_func(){} }
anither_labelled_statement: var label_var

try      { function try_func    (){} var try_var     }
catch(me){ function catch_func  (){} var catch_var   }
finally  { function finally_func(){} var finally_var }


// Mentioning each variable is a sufficient way to make sure it exists. (An
// error will be thrown otherwise.) If it exists and is not a member of the
// global object, then it has to be a member of the call object.
(function() {

ok((f_function1, !('f_function1' in this)),
	'function declarations in function code')
ok((f_variable, !('f_variable' in this)),
	 'var declarations in function code')
ok((f_function2, !('f_function2' in this)),
	 'function declarations in blocks in function code')
ok((f_var2, !('f_var2' in this)),
	 'var declarations in blocks in function code')
ok((f_var3, !('f_var3' in this)),
	 'var declaration within for(;;) header')
ok((f_var4, !('f_var4' in this)),
	 'var declaration within for-in header')
ok((f_if_func, !('f_if_func' in this)),
	 'if() { function ... } in function code')
ok((f_if_var, !('f_if_var' in this)),
	 'if() { var ... } in function code')
ok((f_else_func, !('f_else_func' in this)),
	 'else { function ... } in function code')
ok((f_else_var, !('f_else_var' in this)),
	 'else { var ... } in function code')
ok((f_do_func, !('f_do_func' in this)),
	 'do { function ... } in function code')
ok((f_do_var, !('f_do_var' in this)),
	 'do { var ... } in function code')
ok((f_while_func, !('f_while_func' in this)),
	 'while() { function ... } in function code')
ok((f_while_var, !('f_while_var' in this)),
	 'while() { var ... } in function code')
ok((f_for_func, !('f_for_func' in this)),
	 'for(;;) { function ... } in function code')
ok((f_for_var, !('f_for_var' in this)),
	 'for(;;) { var ... } in function code')
ok((f_for_in_func, !('f_for_in_func' in this)),
	 'for(... in ...) { function ... } in function code')
ok((f_for_in_var, !('f_for_in_var' in this)),
	 'for(... in ...) { var ... } in function code')
ok((f_with_func, !('f_with_func' in this)),
	 'with() { function ... } in function code')
ok((f_with_var, !('f_with_var' in this)),
	 'with() { var ... } in function code')
ok((f_case_func, !('f_case_func' in this)),
	 'case: function... in function code')
ok((f_case_var, !('f_case_var' in this)),
	 'case: var... in function code')
ok((f_default_func, !('f_default_func' in this)),
	 'default: function... in function code')
ok((f_default_var, !('f_default_var' in this)),
	 'default: var... in function code')
ok((f_case2_func, !('f_case2_func' in this)),
	 'default: case: function... in function code')
ok((f_case2_var, !('f_case2_var' in this)),
	 'default: case: var... in function code')
ok((f_label_func, !('f_label_func' in this)),
	 'label: { function... } in function code')
ok((f_label_var, !('f_label_var' in this)),
	 'label: var... in function code')
ok((f_try_func, !('f_try_func' in this)),
	 'try { function... } in function code')
ok((f_try_var, !('f_try_var' in this)),
	 'try { var... } in function code')
ok((f_catch_func, !('f_catch_func' in this)),
	 'catch() { function... } in function code')
ok((f_catch_var, !('f_catch_var' in this)),
	 'catch() { var... } in function code')
ok((f_finally_func, !('f_finally_func' in this)),
	 'finally { function... } in function code')
ok((f_finally_var, !('f_finally_var' in this)),
	 'finally { var... } in function code')

function f_function1 () { } // declaration, not expr
var f_variable
{
	function f_function2(){} var f_var2
}

if(0){ function f_if_func  (){} var f_if_var   }
else { function f_else_func(){} var f_else_var }

do { function f_do_func(){} var f_do_var } while(0)
while(0){ function f_while_func(){} var f_while_var }

for(var f_var3; 0;)    { function f_for_func   (){} var f_for_var    }
for(var f_var4 in this){ function f_for_in_func(){} var f_for_in_var }

with(ok) { function f_with_func(){} var f_with_var }

switch(38){
	case 2:  function f_case_func   (){} var f_case_var
	default: function f_default_func(){} var f_default_var
	case 3:  function f_case2_func  (){} var f_case2_var
}

labelled_statement: { function f_label_func(){} }
anither_labelled_statement: var f_label_var

try      { function f_try_func    (){} var f_try_var     }
catch(me){ function f_catch_func  (){} var f_catch_var   }
finally  { function f_finally_func(){} var f_finally_var }

}())


// ---------------------------------------------------
/* Tests 72-4: initialisation of function params */

0,function(two,parameters){
	ok((two,!('two' in this)) && (parameters,!('parameters' in this)),
		'function params are added to the call object')
}()
,function(home,sweet,home){
	ok(home == 'less',
		'last param is used when two share the same name')
}('me','want','less')
,function(home,sweet,home){
	ok(typeof home == 'undefined',
		'last param is used when two share the same name,' +
		' even if it\'s not defined')
}('Me','Tarzan')


// ---------------------------------------------------
/* Tests 75-84: attributes set by function declarations */

ok(typeof Infinity == 'function',
	'function declarations clobber existing vars')
ok(RegExp() === 'else',
	'function declarations are applied in order')
ok(propertyIsEnumerable('Infinity'),
	'function declarations clobber the DontEnum attribute')
ok(!delete RegExp,
	'function declarations clobber the DontDelete attribute')
readonly = 100
ok(readonly == 100,
	'function declarations clobber the ReadOnly attribute')

function RegExp(){ return 'something' }
function RegExp(){ return 'else'      }
function Infinity(){}
function readonly(){}

eval('function NaN(){} function readonly2(){}')
ok(propertyIsEnumerable('NaN'), 'eval("function NaN...") removes DontEnum')
readonly2 = void 0;
ok(readonly2 === void 2,
	'eval("function readonly_var ...") removes ReadOnly attribute')
ok(delete NaN,	
	'eval("function NaN...") removes DontDelete attribute')

,function(thing){
	ok(!delete thing, 'params are undeleteable')
	eval('function thing(){}')
	ok(delete thing,
		'function(){eval("function ...")} removes the ' +
		'DontDelete attribute')
}()


// ---------------------------------------------------
/* Tests 85-95: attributes set by var declarations */

ok(typeof Boolean === 'function',
	'var declarations leave existing vars alone')
ok(my_other_variable === void 0,
	'vars created by var declarations are initially undefined')
ok(!propertyIsEnumerable('undefined'),
	'var declarations leave the DontEnum attribute of existing vars ' +
	'alone')
ok(delete Boolean,
	'var declarations leave the DontDelete attribute of existing ' +
	'vars alone')
readonly3 = 100
ok(readonly3 != 100,
	'var declarations leave the ReadOnly attribute of existing vars ' +
	'alone')
ok(!delete my_other_variable,
	'vars created by "var" are undeleteable in global code')
eval('var yet_another_var')
ok(delete yet_another_var,
	'vars created by "var" in eval code are deletable')
ok(propertyIsEnumerable('my_other_variable'), 
	'var declarations create enumerable properties')
my_other_variable = 33
ok(my_other_variable === 33, 'var-declared vars are not readonly')

var Boolean = 'RegExp';
var undefined = 73;
var my_other_variable = 3;
var readonly3 = 322;

0,function(thing){
	var eee;
	ok(!delete eee,
		'var-declared vars are undeleteable in function code')
	var thing;
	ok(thing === 356,
	     'var declarations leave existing vars alone in function code')
}(356)


// ===================================================
// 10.1.4 Scope Chain and Identifier Resolution
// ===================================================

/* Tests 96-9 */

obj = { some_property: 7, another_property: 8 }
this.some_property = 9
this.a_unique_property = 383
with(obj) {
	ok(some_property === 7,
		'identifier resolution when two scope chain objects have' +
		' equinominal properties')
	ok(another_property === 8,
		'property of the object at the front of the scope chain')
	ok(a_unique_property === 383,
		'property of object not at the start of the scope chain')
	is_RefError = false
	try { a_non_existent_property }	
	catch(up) { up instanceof ReferenceError && ++ is_RefError }
	ok(is_RefError, 'an identifier of a non-existent property ' +
		'throws a ReferenceError')
}

// ===================================================
// 10.1.6 Activation Object
// ===================================================

/* Tests 100-2 */

ok(function(){ return delete arguments }() === false,
	'arguments is--I mean are--undeletable')

// How do I test that the activation object is the variable object?
// I suppose I'll have to test for its side effects.
0,function(){
	with({}) eval('var Some_var_name_I_ve_not_yet_used = true')
	ok(!('Some_var_name_I_ve_not_yet_used' in this) &&
	      Some_var_name_I_ve_not_yet_used,
		'the activation object is the variable object')

	var global = this;
	function doodaa() {
		ok(this === global, "calling an lvalue whose base object" +
			' is an activation object uses the global object' +
			" as the 'this' value")
	}

	doodaa()
}()
	

// ===================================================
// 10.1.8 Arguments Object
// ===================================================

/* Tests 103-16 */

0,function arguments_test(home,sweet,home,oh,dear){
	ok(arguments.constructor === Object, 'arguments\' prototype')
	ok(!arguments.propertyIsEnumerable('callee'),
		'callee is not enumerable')
	ok(arguments.callee === arguments_test,
		'callee refers to the function itself')
	ok(!arguments.propertyIsEnumerable('length'),
		'arguments.length is not enumerable')
	ok(arguments.length === 4, 'arguments.length is set correctly')
	ok(!(4 in arguments), 'params with no corresponding args are ' +
		'*not* made properties of the arguments object')
	ok(arguments[0] === 'one'   && arguments[1] === 'two'  &&
	   arguments[2] === 'three' && arguments[3] === 'four' &&
	   arguments[4] === void 0,
		'arguments\' numbered properties get set correctly')
	sweet = 'five', home = 'six', oh = 'seven', dear = 'eight'
	ok(arguments[0] === 'one' && arguments[1] === 'five'  &&
	   arguments[2] === 'six' && arguments[3] === 'seven' &&
	   arguments[4] === void 0,
		'changing params changes arguments[0..$#args]')
		// when $#args <= $#params, except when two params have
		// the same name (home)
	var a = arguments;
	a[0] = 'nine', a[1] = 'ten', a[2] = 'eleven', a[3] = 'twelve',
	a[4] = 'thirteen'
	ok(sweet === 'ten' && home === 'eleven' && oh === 'twelve' &&
	   dear  === 'eight',
		'changing arguments[0..$#args] changes params')
		// when $#args <= $#params, except when two params have
		// the same name (home)
	ok(a == '[object Object]', 'arguments\' [[Class]] property')
	ok(!a.propertyIsEnumerable(0) && !a.propertyIsEnumerable(1) &&
	   !a.propertyIsEnumerable(2) && !a.propertyIsEnumerable(3),
		'array-index properties of arguments are not enumerable')
}('one','two','three','four')

,function(two,params) { // more args than params
	two = 'wha', params = 'rima'
	ok(arguments[0] === 'wha' && arguments[1] === 'rima'  &&
	   arguments[2] === 'toru',
		'changing params changes arguments[0..$#params]')
		// when $#params <= $#args
	var a = arguments;
	a[0] = 'ono', a[1] = 'whitu', a[2] = 'waru'
	ok(two === 'ono' && params === 'whitu',
		'changing arguments[0..$#params] changes params')
		// when $#params <= $#args

}('tahi','rua','toru')

,function(arguments){
	ok(arguments === 3,
	   'a param named "arguments" clobbers the usual arguments object')
}(3)

--end--
