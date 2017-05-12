#!perl -T
do './t/jstest.pl' or die __DATA__

// ===================================================
// 15.6.1: Boolean as a function
// 7 tests
// ===================================================

ok(Boolean() === false, 'Boolean()')
ok(Boolean(void 0) === false, 'Boolean(undefined)')
ok(Boolean(876) === true, 'Boolean(number)')
ok(Boolean(true) === true, 'Boolean(boolean)')
ok(Boolean('ffo') === true, 'Boolean(str)')
ok(Boolean(null) === false, 'Boolean(null)')
ok(Boolean({}) === true, 'Boolean(object)')


// ===================================================
// 15.6.2: new Boolean
// 10 tests
// ===================================================

ok(new Boolean().constructor === Boolean, 'prototype of new Boolean')
is(Object.prototype.toString.apply(new Boolean()), '[object Boolean]',
	'class of new Boolean')
ok(new Boolean().valueOf() === false, 'value of new Boolean')
ok(new Boolean(true).valueOf() === true, 'value of new Boolean(true)')
ok(new Boolean(false).valueOf() === false, 'value of new Boolean(false)')

ok(new Boolean(void 0).valueOf() === false, 'new Boolean(undefined)')
ok(new Boolean(876).valueOf() === true, 'new Boolean(number)')
ok(new Boolean("tru").valueOf() === true, 'new Boolean(string)')
ok(new Boolean(null).valueOf() === false, 'new Boolean(null)')
ok(new Boolean({}).valueOf() === true, 'new Boolean(object)')


// ===================================================
// 15.6.3 Boolean
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof Boolean, 'function', 'typeof Boolean');
is(Object.prototype.toString.apply(Boolean), '[object Function]',
	'class of Boolean')
ok(Boolean.constructor === Function, 'Boolean\'s prototype')
ok(Boolean.length === 1, 'Boolean.length')
ok(!Boolean.propertyIsEnumerable('length'),
	'Boolean.length is not enumerable')
ok(!delete Boolean.length, 'Boolean.length cannot be deleted')
is((Boolean.length++, Boolean.length), 1, 'Boolean.length is read-only')
ok(!Boolean.propertyIsEnumerable('prototype'),
	'Boolean.prototype is not enumerable')
ok(!delete Boolean.prototype, 'Boolean.prototype cannot be deleted')
cmp_ok((Boolean.prototype = 7, Boolean.prototype), '!=', 7,
	'Boolean.prototype is read-only')


// ===================================================
// 15.6.4: Boolean prototype
// ===================================================

// 3 tests
is(Object.prototype.toString.apply(Boolean.prototype),
	'[object Boolean]',
	'class of Boolean.prototype')
is(Boolean.prototype, false,
	'value of Boolean.prototype')
ok(peval('shift->prototype',Boolean.prototype) === Object.prototype,
	'Boolean.prototype\'s prototype')


// ===================================================
// 15.6.4.1 Boolean.prototype.constructor
// ===================================================

// 2 tests
ok(Boolean.prototype.hasOwnProperty('constructor'),
	'Boolean.prototype has its own constructor property')
ok(Boolean.prototype.constructor === Boolean,
	'value of Boolean.prototype.constructor')


// ===================================================
// 15.6.4.2: toString
// ===================================================

// 10 tests
method_boilerplate_tests(Boolean.prototype,'toString',0)

// 3 tests for misc this values
0,function(){
	var f = Boolean.prototype.toString;
	var testname='toString with number for this';
	try{f.call(8); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// 2 tests more
ok(new Boolean("foo").toString() === 'true', 'toString (true)')
ok(new Boolean("").toString() === 'false', 'toString (floss)')


// ===================================================
// 15.6.4.3: valueOf
// ===================================================

// 10 tests
method_boilerplate_tests(Boolean.prototype,'valueOf',0)

// 3 tests for misc this values
0,function(){
	var f = Boolean.prototype.valueOf;
	var testname='valueOf with number for this';
	try{f.call(8); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='valueOf with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='valueOf with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// 2 tests more
ok(new Boolean("foo").valueOf() === true, 'valueOf (true)')
ok(new Boolean("").valueOf() === false, 'valueOf (false)')
