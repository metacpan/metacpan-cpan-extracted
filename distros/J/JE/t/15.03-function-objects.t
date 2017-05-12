#!perl -T
do './t/jstest.pl' or die __DATA__

// ===================================================
// 15.3.1 Function()
// ===================================================

// 10 tests
ok(Function()() === void 0, 'Function()')
ok(Function()(838,389,98,8) === void 0,
	'retval of Function() ignores its args')
ok(Function().length === 0, 'Function().length')
ok(Function('return "a"').length === 0, 'Function(thing).length')
ok(Function('return "a"')() === "a", 'Function(thing) uses thing as body')
ok(Function('a,x/*','*/,c ','').length === 3, 'Function parameter lists')
ok(Function('a,x/*','*/,b\u200et','return[a,x,bt].join(" ")')(27,3,"a") ===
	'27 3 a', 'Function with format chars in the param list')

error = false
try{Function('eee,,,','body')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function with bad param list')

error = false
try{Function('eee','bo++dy')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function with bad body')

0,function(){
	var undefined = 'foo';
	ok(Function('return undefined')() === void 0,
		'Function()\'s scope chain')
}()

// 10 tests for type conversion
ok(Function(undefined)() === undefined, 'Function(undefined)')
ok(Function(true)() === undefined, 'Function(bool)')
ok(Function(34)()=== undefined, 'Function(num)')
ok(Function(null)()=== undefined, 'Function(null)')
error = false
try{Function({})}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (obj)')
ok(Function(void 0, 'return undefined')(34) === 34,
	'Function(undefined, body)')
error = false
try{Function(22, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (num, body)')

/* These two don’t die, because JE is lenient (which the spec allows):
error = false
try{Function(true, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (bool, body)')
error = false
try{Function(null, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (null, body)')
*/

// These work with JE, but if I ever make it more strict, I need to replace
// these tests with those above. I used to think it was impossible to test
// that the vars named in the param list are created, since they supposedly
// could not be accessed by name, but they actually *can* be accessed by
// name if we use escapes.
ok(Function(true, 'return tru\\u0065')('blext') === 'blext',
  'Function(bool, body)')
ok(Function(null, 'return n\\u0075ll')('cled')=== 'cled',
  'Function(null, body)')


error = false
try{Function({})}
catch(e){error = e}
ok(error instanceof SyntaxError, 'Function (obj, body)')


// ===================================================
// 15.3.2 new Function()
// ===================================================

// 10 tests
ok(new Function()() === void 0, 'new Function()')
ok(new Function()(838,389,98,8) === void 0,
	'retval of new Function() ignores its args')
ok(new Function().length === 0, 'new Function().length')
ok(new Function('return "a"').length === 0, 'new Function(thing).length')
ok(new Function('return "a"')() === "a",
	'new Function(thing) uses thing as body')
ok(new Function('a,x/*','*/,c ','').length === 3, 
	'new Function parameter lists')
ok(new Function('a,x/*','*/,b\u200et','return[a,x,bt].join(" ")')(27,3,"a")
	=== '27 3 a', 'new Function with format chars in the param list')

error = false
try{new Function('eee,,,','body')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function with bad param list')

error = false
try{new Function('eee','bo++dy')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function with bad body')

0,function(){
	var undefined = 'foo';
	ok(new Function('return undefined')() === void 0,
		'new Function()\'s scope chain')
}()

// 10 tests for type conversion
ok(new Function(undefined)() === undefined, 'new Function(undefined)')
ok(new Function(true)() === undefined, 'new Function(bool)')
ok(new Function(34)()=== undefined, 'new Function(num)')
ok(new Function(null)()=== undefined, 'new Function(null)')
error = false
try{new Function({})}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (obj)')
ok(new Function(void 0, 'return undefined')(34) === 34,
	'new Function(undefined, body)')
error = false
try{new Function(22, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (num, body)')

/* These two don’t die, because JE is lenient (which the spec allows):
error = false
try{new Function(true, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (bool, body)')
error = false
try{new Function(null, '')}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (null, body)')
*/

// These work with JE, but if I ever make it more strict, I need to replace
// these tests with those above. I used to think it was impossible to test
// that the vars named in the param list are created, since they supposedly
// could not be accessed by name, but they actually *can* be accessed by
// name if we use escapes.
ok(new Function(true, 'return tru\\u0065')('blext') === 'blext',
  'new Function(bool, body)')
ok(new Function(null, 'return n\\u0075ll')('cled')=== 'cled',
  'new Function(null, body)')


error = false
try{new Function({})}
catch(e){error = e}
ok(error instanceof SyntaxError, 'new Function (obj, body)')


// ===================================================
// 15.3.3 Function
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof Function, 'function', 'typeof Function');
is(Object.prototype.toString.apply(Function), '[object Function]',
	'class of Function')
ok(Function.constructor === Function, 'Function\'s prototype')
ok(Function.length === 1, 'Function.length')
ok(!Function.propertyIsEnumerable('length'),
	'Function.length is not enumerable')
ok(!delete Function.length, 'Function.length cannot be deleted')
is((Function.length++, Function.length), 1, 'Function.length is read-only')
ok(!Function.propertyIsEnumerable('prototype'),
	'Function.prototype is not enumerable')
ok(!delete Function.prototype, 'Function.prototype cannot be deleted')
//diag(Function.prototype)
cmp_ok((Function.prototype = 7, Function.prototype), '!=', 7,
	'Function.prototype is read-only')


// ===================================================
// 15.3.4 Function.prototype
// ===================================================

// 5 tests
is(Object.prototype.toString.apply(Function.prototype),
	'[object Function]',
	'class of Function.prototype')
ok(Function.prototype(1,2,{},[],"243987",null,false,undefined) === void 0,
	'Function.prototype()')
ok(peval('shift->prototype',Function.prototype) === Object.prototype,
	'Function.prototype\'s prototype')
ok(!Function.prototype.hasOwnProperty('valueOf'),
	'Function.prototype.valueOf')
ok(!Function.prototype.propertyIsEnumerable('length'),
	'Function.prototype.length is not enumerable')


// ===================================================
// 15.3.4.1 Function.prototype.constructor
// ===================================================

// 2 tests
ok(Function.prototype.hasOwnProperty('constructor'),
	'Function.prototype has its own constructor property')
ok(Function.prototype.constructor === Function,
	'value of Function.prototype.constructor')


// ===================================================
// 15.3.4.2 Function.prototype.toString
// ===================================================

// 10 tests
method_boilerplate_tests(Function.prototype,'toString',0)

// 4 tests

try{ Function.prototype.toString.call({});
  fail('toString dies on non-functions')}
catch(oo){ok(oo instanceof TypeError, 'toString dies on non-functions')}

try { is(eval("0,"+new Function('return "foo"//').toString())(), 'foo',
	'new Function(...).toString()') }
catch(e) { fail('new Function(...).toString()'); diag(e) }

ok(function(){ return "bar" }.toString().match(
	/^function anon\d+\(\) \{ return "bar" \n}$/
), 'toString() on function created by function expression')
	|| diag(function(){ return "bar" } + ' does not match');

ok(eval.toString().match(/native code/), 'toString on native function')


// ===================================================
// 15.3.4.3 Function.prototype.apply
// ===================================================

// 10 tests
method_boilerplate_tests(Function.prototype,'apply',2)

// 17 tests
error =  false
try { o = {f: Function.prototype.apply}; o.f();}
catch(ie) { error = ie instanceof TypeError}
ok(error, 'apply throws a TypeError when its this value is not a func')
ok(function(){return this}.apply(null) === this, 'apply(null)')
ok(function(){return this}.apply(void 0) === this, 'apply(undefined)')
ok(function(){return this}.apply() === this, 'apply()')
is({}.toString.call(function(){return this}.apply('')), '[object String]',
	'apply(str)')
is({}.toString.call(function(){return this}.apply(5)), '[object Number]',
	'apply(num)')
is({}.toString.call(function(){return this}.apply(true)),
	'[object Boolean]',
	'apply(bool)')
ok(function(){return this}.apply(o) === o,
	'apply(object) passes exactly the same object')
is(function(){return arguments}.apply({},null).length, 0,
	'apply with null for the arg array')
is(function(){return arguments}.apply({},undefined).length, 0,
	'apply with undefined for the arg array')
is(function(){return arguments}.apply({}).length, 0,
	'apply with omitted arg array')
error =  false
try { new Function().apply({},'') }
catch(ie) { error = ie instanceof TypeError}
ok(error, 'apply with string for the arg array')
error =  false
try { Function.prototype.apply(3,4) }
catch(it) { it instanceof TypeError && (error = 1) }
ok(error, 'apply with number for the arg array')
error =  false
try { new Function().apply({},false) }
catch(ie) { error = ie instanceof TypeError}
ok(error, 'apply with boolean for the arg array')
error =  false
try { new Function().apply({},{}) }
catch(ie) { error = ie instanceof TypeError}
ok(error, 'apply with non-array object for the arg array')

function join_args (args) {
	var str = '';
	for(var i = 0; i< args.length;++i) str += ',' + args[i];
	return str.substring(1)
}
is(join_args(function(){return arguments}.apply({}, [1,2,3])), '1,2,3',
	'apply with array of args')
;(function(){
	is(join_args(function(){return arguments}.apply({},arguments)),
	  '4,5,6',
	  'apply with arguments object')
})(4,5,6)


// ===================================================
// 15.3.4.4 Function.prototype.call
// ===================================================

// 10 tests
method_boilerplate_tests(Function.prototype,'call',1)

// 9 tests
error =  false
try { o = {f: Function.prototype.call}; o.f();}
catch(ie) { error = ie instanceof TypeError}
ok(error, 'call with a this value that is not a function')
ok(function(){return this}.call(void 0) === this, 'call(undefined)')
ok(function(){return this}.call(null) === this, 'call(null)')
ok(function(){return this}.call() === this, 'call()')
String.prototype.twoString = Number.prototype.twoString = 
Boolean.prototype.twoString = {}.toString;
is(function(){return this}.call('').twoString(), '[object String]',
	'call(str)')
is(function(){return this}.call(5).twoString(), '[object Number]',
	'call(num)')
is(function(){return this}.call(true).twoString(),
	'[object Boolean]',
	'call(bool)')
ok(function(){return this}.call(o) === o, 'call(object)')
is(join_args(function(){return arguments}.call(1,2,3,4)),'2,3,4',
	'call with multiple arguments')

// ===================================================
// 15.3.5 Properties of functions
// 8 test
// ===================================================

is({}.toString.call(function(){}), '[object Function]',
	'class of a function')

;(function(){
	f = function(a,b,c) { }
	ok(f.length === 3, 'value of length')
	f.length = 4
	is(f.length, 3, 'length is read-only')
	delete f.length
	ok('length' in f, 'length is undeletable')
	var a = []
	for(a[a.length] in f);
	ok(!/\blength\b/.test(a), 'length is not enumerable')

	delete f.prototype
	ok('prototype' in f, 'prototype is undeletable')
	f.prototype={o:'b'}
	is(f.prototype.o, 'b', 'prototype is not read-only')
	is(new f().o, 'b',
		'and the new prototype property is actually used')
}())

// There’s no need to test [[HasInstance]] (15.3.5.3) here, because
// 11.08-relational.t takes care of that.
