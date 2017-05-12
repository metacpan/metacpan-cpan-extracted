#!perl -T
do './t/jstest.pl' or die __DATA__

// ===================================================
// 15.7.1: Number as a function
// 7 tests
// ===================================================

ok(Number() === 0, 'Number()')
ok(is_nan(Number(void 0)), 'Number(undefined)')
ok(Number(876) === 876, 'Number(number)')
ok(Number(true) === 1, 'Number(boolean)')
ok(Number('34') === 34, 'Number(str)')
ok(Number(null) === 0, 'Number(null)')
ok(is_nan(Number({})), 'Number(object)')


// ===================================================
// 15.7.2: new Number
// 10 tests
// ===================================================

ok(new Number().constructor === Number, 'prototype of new Number')
is(Object.prototype.toString.apply(new Number()), '[object Number]',
	'class of new Number')
ok(new Number().valueOf() === 0, 'value of new Number')
ok(new Number(true).valueOf() === 1, 'value of new Number(true)')
ok(new Number(false).valueOf() === 0, 'value of new Number(false)')
ok(is_nan(new Number(void 0).valueOf()), 'new Number(undefined)')
ok(new Number(876).valueOf() === 876, 'new Number(number)')
ok(new Number("37.3").valueOf() == 37.3, 'new Number(string)')
ok(new Number(null).valueOf() === 0, 'new Number(null)')
ok(is_nan(new Number({}).valueOf()), 'new Number(object)')

// 1 test
is(peval(
	'my $w = 0;' +
	'local $SIG{__WARN__} = sub { ++$w };' +
	'shift->eval(q"new Number");'+
	'$w',
	this), 0, 'new Number doesn\'t warn');


// ===================================================
// 15.7.3 Number
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof Number, 'function', 'typeof Number');
is(Object.prototype.toString.apply(Number), '[object Function]',
	'class of Number')
ok(Number.constructor === Function, 'Number\'s prototype')
ok(Number.length === 1, 'Number.length')
ok(!Number.propertyIsEnumerable('length'),
	'Number.length is not enumerable')
ok(!delete Number.length, 'Number.length cannot be deleted')
is((Number.length++, Number.length), 1, 'Number.length is read-only')
ok(!Number.propertyIsEnumerable('prototype'),
	'Number.prototype is not enumerable')
ok(!delete Number.prototype, 'Number.prototype cannot be deleted')
cmp_ok((Number.prototype = 7, Number.prototype), '!=', 7,
	'Number.prototype is read-only')


// ===================================================
// 15.7.3.2 Number.MAX_VALUE
// 4 tests
// ===================================================

try{ skip("MAX- and MIN_VALUE are not supported",8);

ok(!Number.propertyIsEnumerable('MAX_VALUE'),
	'Number.MAX_VALUE is not enumerable')
ok(!delete Number.MAX_VALUE, 'Number.MAX_VALUE cannot be deleted')
cmp_ok((Number.MAX_VALUE = 7, Number.MAX_VALUE), '!=', 7,
	'Number.MAX_VALUE is read-only')
ok(Number.MAX_VALUE === "What value do we put here?", 'value of MAX_VALUE')

// ===================================================
// 15.7.3.3 Number.MIN_VALUE
// 4 tests
// ===================================================

ok(!Number.propertyIsEnumerable('MIN_VALUE'),
	'Number.MIN_VALUE is not enumerable')
ok(!delete Number.MIN_VALUE, 'Number.MIN_VALUE cannot be deleted')
cmp_ok((Number.MIN_VALUE = 7, Number.MIN_VALUE), '!=', 7,
	'Number.MIN_VALUE is read-only')
ok(Number.MIN_VALUE === "What value do we put here?", 'value of MIN_VALUE')

}catch(_){}


// ===================================================
// 15.7.3.4 Number.NaN
// 4 tests
// ===================================================

ok(!Number.propertyIsEnumerable('NaN'),
	'Number.NaN is not enumerable')
ok(!delete Number.NaN, 'Number.NaN cannot be deleted')
cmp_ok((Number.NaN = 7, Number.NaN), '!=', 7,
	'Number.NaN is read-only')
ok(is_nan(Number.NaN), 'value of NaN')


// ===================================================
// 15.7.3.5 Number.NEGATIVE_INFINITY
// 4 tests
// ===================================================

ok(!Number.propertyIsEnumerable('NEGATIVE_INFINITY'),
	'Number.NEGATIVE_INFINITY is not enumerable')
ok(!delete Number.NEGATIVE_INFINITY,
 'Number.NEGATIVE_INFINITY cannot be deleted')
cmp_ok((Number.NEGATIVE_INFINITY = 7, Number.NEGATIVE_INFINITY), '!=', 7,
	'Number.NEGATIVE_INFINITY is read-only')
ok(
 Number.NEGATIVE_INFINITY.toString() == "-Infinity"
 && Number.NEGATIVE_INFINITY < 0
 && Number.NEGATIVE_INFINITY+1 === Number.NEGATIVE_INFINITY,
 'value of NEGATIVE_INFINITY'
)


// ===================================================
// 15.7.3.6 Number.POSITIVE_INFINITY
// 4 tests
// ===================================================

ok(!Number.propertyIsEnumerable('POSITIVE_INFINITY'),
	'Number.POSITIVE_INFINITY is not enumerable')
ok(!delete Number.POSITIVE_INFINITY,
 'Number.POSITIVE_INFINITY cannot be deleted')
cmp_ok((Number.POSITIVE_INFINITY = 7, Number.POSITIVE_INFINITY), '!=', 7,
	'Number.POSITIVE_INFINITY is read-only')
ok(
 Number.POSITIVE_INFINITY.toString() == "Infinity"
 && Number.POSITIVE_INFINITY > 0
 && Number.POSITIVE_INFINITY+1 === Number.POSITIVE_INFINITY,
 'value of POSITIVE_INFINITY'
)


// ===================================================
// 15.7.4: Number prototype
// ===================================================

// 3 tests
is(Object.prototype.toString.apply(Number.prototype),
	'[object Number]',
	'class of Number.prototype')
is(1/Number.prototype, Infinity, // by dividing by zero we can distinguish
	'value of Number.prototype')  // +0 from -0
ok(peval('shift->prototype',Number.prototype) === Object.prototype,
	'Number.prototype\'s prototype')


// ===================================================
// 15.7.4.1 Number.prototype.constructor
// ===================================================

// 2 tests
ok(Number.prototype.hasOwnProperty('constructor'),
	'Number.prototype has its own constructor property')
ok(Number.prototype.constructor === Number,
	'value of Number.prototype.constructor')


// ===================================================
// 15.7.4.2: toString
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toString',1)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toString;
	var testname='toString with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// more tests ...


// ===================================================
// 15.7.4.3: toLocaleString
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toLocaleString',0)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toLocaleString;
	var testname='toLocaleString with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toLocaleString with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toLocaleString with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// more tests ...


// ===================================================
// 15.7.4.4: valueOf
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'valueOf',0)

// 4 tests for misc this values
0,function(){
	var f = Number.prototype.valueOf;
	var testname='valueOf with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='valueOf with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='valueOf with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	ok(f.call(3)===3, 'valueOf with plain number for this')
}()

// 1 test more
ok( new Number().valueOf() === 0, 'valueOf' )


// ===================================================
// 15.7.4.5: toFixed
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toFixed',1)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toFixed;
	var testname='toFixed with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toFixed with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toFixed with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// 10 tests
ok(NaN.toFixed() === "NaN", 'NaN.toFixed')
ok(27.3.toFixed() === "27", 'toFixed with no args')
is(27.3.toFixed(NaN), "27", 'toFixed with NaN arg')
is(27.37.toFixed(1.9), "27.4", 'toFixed with float arg')
is(27.3.toFixed(0), "27", 'toFixed with 0 arg')
is(30.1.toFixed(5), "30.10000", 'toFixed returns trailing zeroes')
is(30.125.toFixed(2), "30.13", 'toFixed rounds 5 up')
is(1.5.toFixed(0), "2", 'toFixed(0) rounds 5 up')
is(.1.toFixed(2), "0.10", 'toFixed returns a leading 0.')
is(1000000000000000000001..toFixed(7), 1000000000000000000001..toString(),
   'toFixed uses toString for really big numbers');


// ===================================================
// 15.7.4.6: toExponential
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toExponential',1)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toExponential;
	var testname='toExponential with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toExponential with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toExponential with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// 15 tests
ok(NaN.toExponential(-200) === "NaN", 'NaN.toExponential')
ok((-Infinity).toExponential(-200) === "-Infinity", "-inf.toExponential")
ok(Infinity.toExponential(-200) === "Infinity", "inf.toExponential")
is(3..toExponential(), '3e+0', 'integer.toExponential')
is(300..toExponential(), '3e+2', 'power of ten .toExponential')
is(37.2.toExponential(), '3.72e+1', 'float>1 .toExponential')
is(.00372.toExponential(), '3.72e-3', 'positive float<1 .toExponential')
is(0..toExponential(), '0e+0', '0..toExponential()')
is(37.2.toExponential(1), '3.7e+1', 'toExponential with arg')
is(37.2.toExponential(1.9), '3.7e+1', 'toExponential with float arg')
is(37.2.toExponential(NaN), '4e+1', 'toExponential with nan arg')
is(30.125.toExponential(3), '3.013e+1', 'toExponential with arg rounds up')
is(9.5.toExponential(0), '1e+0', '9.5.toExponential(0)')
is(1.5.toExponential(0), '2e+0', 'toExponential with 0 arg rounds up')
is((-1.).toExponential(), '-1e+0', 'negative .toExponential')


// ===================================================
// 15.7.4.7: toPrecision
// ===================================================

// 10 tests
method_boilerplate_tests(Number.prototype,'toPrecision',1)

// 3 tests for misc this values
0,function(){
	var f = Number.prototype.toPrecision;
	var testname='toPrecision with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toPrecision with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toPrecision with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// 17 test
ok(80..toPrecision() === '80', 'int.toPrecision with no args stringifies')
ok(80.1.toPrecision() === '80.1',
  'float.toPrecision with no args stringifies')
ok(NaN.toPrecision(1) === 'NaN', 'NaN.toPrecision')
is(Infinity.toPrecision(1), 'Infinity', 'inf.toPrecision')
is((-Infinity).toPrecision(1), '-Infinity', '-inf.toPrecision')
is(0..toPrecision(1), '0', '0..toPrecision(1)')
is(0..toPrecision(7), '0.000000', '0..toPrecision(7)')
is(.0000001.toPrecision(1), '1.e-7', '.000001.toPrecision(1)')
is(10..toPrecision(1), '1.e+1', '10..toPrecision(1)')
is(100..toPrecision(1), '1.e+2', '100..toPrecision(2)')
is(100..toPrecision(3), '100', '100..toPrecision(3)')
is((-100).toPrecision(3), '-100', '(-100)..toPrecision(3)')
try{
 skip("not reliable enough",2);
 is(1.5.toPrecision(1), '2', '1.5.toPrecision(1)')
 is(9.5.toPrecision(1), '1.e+1', '9.5.toPrecision(1)')
}catch(oeunth){}
is(80..toPrecision(4), '80.00', '80..toPrecision(4)')
is(.01.toPrecision(1), '0.01', '.01.toPrecision(1)')
is(80..toPrecision(4.6), '80.00', 'toPrecision with float arg')


diag('TO DO: Finish writing this test script');
// We still need tests for toString and toLocaleString
