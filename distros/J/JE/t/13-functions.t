#!perl -T
do './t/jstest.pl' or die __DATA__

plan('tests', 44)

// ===================================================
// 13 Semantics for the different function syntaxes
// ===================================================

// The addition of the function created by a declaration to the correct
// object (the variable object) is tested in
// 10.01-execution-context-definitions.t. No need to test that here.

/* Tests 1-5 */

0,function(){
	var foo;
	ok(typeof(foo = function(a,b,c){return foo}) == 'function',
		'value returned by func expr')
	ok(foo==foo(), 'scope chain of func expr')
}()
0,function(){
	var foo;
	ok(typeof(foo = function bar(a,b){
		bar = 7; delete bar; return [foo,bar]
	  }) == 'function',
		'value returned by func expr w/ident')
	var bar;
	is(bar, undefined,
		'function expr with ident is not callable by name')

	var ret = foo()
	ok(foo==ret[0] && foo ==ret[1],
		'scope chain of func expr with ident')
}()

// A FunctionBody’s return value is tested in 12-statements.t, so we
// don’t need to test that here either.

// ===================================================
// 13.2 Creating functions
// ===================================================

/* Tests 6-23 */

function d(e,f,g){
	if(e==1) throw 1;
	if(e==2) return 43
	if(e==3) return []
	34 // make sure this isn't returned
}
e = function (f,g) {
	if(f==1) throw 1;
	if(f==2) return 44
	if(f==3) return []
	4
}
i = function name(j) {
	if(j==1) throw 10;
	if(j==2) return 45
	if(j==3) return []
	67
}

is (Object.prototype.toString.apply(d), '[object Function]',
	'[[Class]] of declared function')
is (Object.prototype.toString.apply(e), '[object Function]',
	'[[Class]] of expressed function')
is (Object.prototype.toString.apply(i), '[object Function]',
	'[[Class]] of expressed named function')
ok(d.constructor === Function, 'prototype of declared function')
ok(e.constructor === Function, 'prototype of expressed function')
ok(i.constructor === Function, 'prototype of expressed function')
is(d.length, 3, 'length of declared function')
is(e.length, 2, 'length of expressed function')
is(i.length, 1, 'length of expressed named function')
is(d.prototype, '[object Object]', 'class of proto of decl func')
is(e.prototype, '[object Object]', 'class of proto of expr func')
is(i.prototype, '[object Object]', 'class of proto of expr named func')
ok(!d.prototype.propertyIsEnumerable('constructor'),
	'unenumerability of decl func .prototype.constructor')
ok(!e.prototype.propertyIsEnumerable('constructor'),
	'unenumerability of expr func .prototype.constructor')
ok(!i.prototype.propertyIsEnumerable('constructor'),
	'unenumerability of expr named func .prototype.constructor')
ok(d.prototype.constructor === d, 'decl func .prototype.constructor')
ok(e.prototype.constructor === e, 'expr func .prototype.constructor')
ok(i.prototype.constructor === i, 'expr named func .prototype.constructor')

// ===================================================
// 13.2.1 [[Call]]
// ===================================================

/* Tests 24-32 */

is(d(), 'undefined','ret val of declared function without explicit return')
is(e(), 'undefined','retval of run-time function without explicit return')
is(i(), 'undefined','ret val of named run-time func w/o explicit return')
error = false
try{d(1)}catch(e){error=true}
ok(error,'propagation of errors through calls to declared functions')
error = false
try{e(1)}catch(e){error=true}
ok(error,'propagation of errors through calls to run-time functions')
error = false
try{i(1)}catch(e){error=true}
ok(error,'propagation of errors through calls to named run-time functions')
is(d(2), 43,'return value of declared func with explicit return')
is(e(2), 44,'return value of run-time func with explicit return')
is(i(2), 45,'return value of named run-time func with explicit return')


// ===================================================
// 13.2.2 [[Construct]]
// ===================================================

/* Tests 33-44 */

d.prototype = e.prototype = i.prototype = ['foo'];
D = new d, E = new e, I = new i;

is(Object.prototype.toString.apply(D), '[object Object]',
   'class of default object returned by [[Construct]] for declared func')
is(Object.prototype.toString.apply(E), '[object Object]',
   'class of default object returned by [[Construct]] for run-time func')
is(Object.prototype.toString.apply(I), '[object Object]',
   'class of def obj returned by [[Construct]] for named run-time func')

is(D[0], 'foo',
	'prototype of object returned by [[Construct]] for decl func')
is(E[0], 'foo',
	'prototype of object returned by [[Construct]] for run-time func')
is(I[0], 'foo',
	'proto of obj returned by [[Construct]] for named run-time func')

d.prototype = e.prototype = i.prototype = 'this function has no prototype';
D = new d, E = new e, I = new i;

ok(D.constructor === Object,
	'object returned by decl constructor with no prototype property')
ok(E.constructor === Object,
	'object returned by run-time constructor with no prototype prop')
ok(I.constructor === Object,
	'obj returned by named run-time constr with no prototype property')

ok(new d(3).constructor === Array,
	'obj explicitly returned by declared constructor')
ok(new e(3).constructor === Array,
	'obj explicitly returned by run-time constructor')
ok(new i(3).constructor === Array,
	'obj explicitly returned by named run-time constr')
