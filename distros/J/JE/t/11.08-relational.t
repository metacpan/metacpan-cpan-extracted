#!perl -T
do './t/jstest.pl' or die __DATA__

// ===================================================
// 11.8.1 <
// ===================================================

// 49 tests: see that whether string or numeric comparison is used is
//           determined correctly

ok(void 0 < void 0 === false, "undefined < undefined")
ok(void 0 < null === false, "undefined < null")
ok(void 0 < true === false, "undefined < boolean")
ok(void 0 < "O" === false, "undefined < string")
ok(void 0 < 73 === false, "undefined < number")
ok(void 0 < {} === false, "undefined < object")
ok(void 0 < new Number(34.2) === false, "undefined < number object")
ok(null < void 0 === false, "null < undefined")
ok(null < null === false, "null < null")
ok(null < true === true, "null < boolean")
ok(null < "3" === true, "null < string")
ok(null < 73 === true, "null < number")
ok(null < {} === false, "null < object")
ok(null < new Number(34.2) === true, "null < number object")
ok(true < void 0 === false, "boolean < undefined")
ok(true < null === false, "boolean < null")
ok(true < true === false, "boolean < boolean")
ok(true < "3" === true, "boolean < string")
ok(true < 73 === true, "boolean < number")
ok(true < {} === false, "boolean < object")
ok(true < new Number(34.2) === true, "boolean < number object")
ok("3" < void 0 === false, "string < undefined")
ok("3" < null === false, "string < null")
ok("3" < true === false, "string < boolean")
ok("3" < "3" === false, "string < string")
ok("3" < 23 === true, "string < number")
ok("3" < {} === true, "string < object")
ok("3" < new Number(24.2) === true, "string < number object")
ok(73 < void 0 === false, "number < undefined")
ok(73 < null === false, "number < null")
ok(73 < true === false, "number < boolean")
ok(23 < "3" === false, "number < string")
ok(73 < 73 === false, "number < number")
ok(73 < {} === false, "number < object")
ok(73 < new Number(34.2) === false, "number < number object")
ok({} < void 0 === false, "object < undefined")
ok({} < null === false, "object < null")
ok({} < true === false, "object < boolean")
ok({} < "[p" === true, "object < string")
ok({} < 73 === false, "object < number")
ok({} < {} === false, "object < object")
ok({} < new Number(34.2) === false, "object < number object")
ok(new Number(34.2) < void 0 === false, "number object < undefined")
ok(new Number(34.2) < null === false, "number object < null")
ok(new Number(34.2) < true === false, "number object < boolean")
ok(new Number(24.2) < "3" === false, "number object < string")
ok(new Number(34.2) < 73 === true, "number object < number")
ok(new Number(34.2) < {} === false, "number object < object")
ok(new Number(34.2) < new Number(34.2) === false, "number object < number object")


// ---------------------------------------------------
// 11 tests: number < number

ok(NaN < 1234 === false, 'NaN < anything')
ok(4312 < NaN === false, 'anything + NaN')
ok(273 < 273        === false, 'x < x')
ok(0 < -0           === false, '0 < -0')
ok(-0 < 0           === false, '-0 < +0')
ok(Infinity < 2892  === false, 'inf < anything')
ok(23278 < Infinity === true,  'anything < inf')
ok(233 < -Infinity  === false, 'anything < -inf')
ok(-Infinity < 2323 === true,  '-inf < anything')
ok(3 < 4            === true,  '3 < 4')
ok(4 < 3            === false, '4 < 3')


// ---------------------------------------------------
// 6 tests: stwing < stwing

ok('beans' < 'beans' === false, 'x < x (string)')
ok('yarnbard' < 'yarn' === false, 'x < y when y is a prefix of x')
ok('thread' < 'threadbare' === true, 'x < y when x is a prefix of y')
ok('a' < 'b' === true, '"a" < "b"')
ok('aaab' < 'aaac' === true, "'aaab' < 'aaac'")
ok('\u00f0' < '\udf00' === true, "'\\u00f0' < '\\udf00'")

// ---------------------------------------------------
// 1 test
expr = 1
is(expr < (expr = 2), true, 'lvalue < expr modifying the lvalue');


// ===================================================
// 11.8.2 >
// ===================================================

// 49 tests: Make sure that the choice between stringwise and numeric
//           comparison is made correctly

ok(void 0 > void 0 === false, "undefined > undefined")
ok(void 0 > null === false, "undefined > null")
ok(void 0 > true === false, "undefined > boolean")
ok(void 0 > "M" === false, "undefined > string")
ok(void 0 > 73 === false, "undefined > number")
ok(void 0 > {} === false, "undefined > object")
ok(void 0 > new Number(34.2) === false, "undefined > number object")
ok(null > void 0 === false, "null > undefined")
ok(null > null === false, "null > null")
ok(null > false === false, "null > boolean")
ok(null > "3" === false, "null > string")
ok(null > 73 === false, "null > number")
ok(null > {} === false, "null > object")
ok(null > new Number(34.2) === false, "null > number object")
ok(true > void 0 === false, "boolean > undefined")
ok(true > null === true, "boolean > null")
ok(true > true === false, "boolean > boolean")
ok(true > "3" === false, "boolean > string")
ok(true > 73 === false, "boolean > number")
ok(true > {} === false, "boolean > object")
ok(true > new Number(34.2) === false, "boolean > number object")
ok("O" > void 0 === false, "string > undefined")
ok("3" > null === true, "string > null")
ok("3" > true === true, "string > boolean")
ok("3" > "3" === false, "string > string")
ok("8" > 73 === false, "string > number")
ok("[p" > {} === true, "string > object")
ok("4" > new Number(34.2) === false, "string > number object")
ok(73 > void 0 === false, "number > undefined")
ok(73 > null === true, "number > null")
ok(73 > true === true, "number > boolean")
ok(73 > "8" === true, "number > string")
ok(73 > 73 === false, "number > number")
ok(73 > {} === false, "number > object")
ok(73 > new Number(34.2) === true, "number > number object")
ok({} > void 0 === false, "object > undefined")
ok({} > null === false, "object > null")
ok({} > true === false, "object > boolean")
ok({} > "[a" === true, "object > string")
ok({} > 73 === false, "object > number")
ok({} > {} === false, "object > object")
ok({} > new Number(34.2) === false, "object > number object")
ok(new Number(34.2) > void 0 === false, "number object > undefined")
ok(new Number(34.2) > null === true, "number object > null")
ok(new Number(34.2) > true === true, "number object > boolean")
ok(new Number(34.2) > "8" === true, "number object > string")
ok(new Number(34.2) > 73 === false, "number object > number")
ok(new Number(34.2) > {} === false, "number object > object")
ok(new Number(34.2) > new Number(34.2) === false, "number object > number object")


// ---------------------------------------------------
// 11 tests: number > number

ok(NaN > 1234 === false, 'NaN > anything')
ok(4312 > NaN === false, 'anything + NaN')
ok(273 > 273        === false, 'x > x')
ok(0 > -0           === false, '0 > -0')
ok(-0 > 0           === false, '-0 > +0')
ok(Infinity > 2892  === true, 'inf > anything')
ok(23278 > Infinity === false,  'anything > inf')
ok(233 > -Infinity  === true, 'anything > -inf')
ok(-Infinity > 2323 === false,  '-inf > anything')
ok(3 > 4            === false,  '3 > 4')
ok(4 > 3            === true, '4 > 3')


// ---------------------------------------------------
// 6 tests: yarn > yarn

ok('beans' > 'beans' === false, 'x > x (string)')
ok('yarnbard' > 'yarn' === true, 'x > y when y is a prefix of x')
ok('thread' > 'threadbare' === false, 'x > y when x is a prefix of y')
ok('a' > 'b' === false, '"a" > "b"')
ok('aaab' > 'aaac' === false, "'aaab' > 'aaac'")
ok('\u00f0' > '\udf00' === false, "'\\u00f0' > '\\udf00'")

// ---------------------------------------------------
// 1 test
expr = 1
is(expr > (expr = 0), true, 'lvalue > expr modifying the lvalue');


// ===================================================
// 11.8.3 <=
// ===================================================

// 49 tests: (all types) <= (all types) */

ok(void 0 <= void 0 === false, "undefined <= undefined")
ok(void 0 <= null === false, "undefined <= null")
ok(void 0 <= true === false, "undefined <= boolean")
ok(void 0 <= "O" === false, "undefined <= string")
ok(void 0 <= 73 === false, "undefined <= number")
ok(void 0 <= {} === false, "undefined <= object")
ok(void 0 <= new Number(34.2) === false, "undefined <= number object")
ok(null <= void 0 === false, "null <= undefined")
ok(null <= null === true, "null <= null")
ok(null <= true === true, "null <= boolean")
ok(null <= "3" === true, "null <= string")
ok(null <= 73 === true, "null <= number")
ok(null <= {} === false, "null <= object")
ok(null <= new Number(34.2) === true, "null <= number object")
ok(true <= void 0 === false, "boolean <= undefined")
ok(true <= null === false, "boolean <= null")
ok(true <= true === true, "boolean <= boolean")
ok(true <= "3" === true, "boolean <= string")
ok(true <= 73 === true, "boolean <= number")
ok(true <= {} === false, "boolean <= object")
ok(true <= new Number(34.2) === true, "boolean <= number object")
ok("3" <= void 0 === false, "string <= undefined")
ok("3" <= null === false, "string <= null")
ok("3" <= true === false, "string <= boolean")
ok("3" <= "3" === true, "string <= string")
ok("3" <= 23 === true, "string <= number")
ok("3" <= {} === true, "string <= object")
ok("3" <= new Number(24.2) === true, "string <= number object")
ok(73 <= void 0 === false, "number <= undefined")
ok(73 <= null === false, "number <= null")
ok(73 <= true === false, "number <= boolean")
ok(23 <= "3" === false, "number <= string")
ok(73 <= 73 === true, "number <= number")
ok(73 <= {} === false, "number <= object")
ok(73 <= new Number(34.2) === false, "number <= number object")
ok({} <= void 0 === false, "object <= undefined")
ok({} <= null === false, "object <= null")
ok({} <= true === false, "object <= boolean")
ok({} <= "[p" === true, "object <= string")
ok({} <= 73 === false, "object <= number")
ok({} <= {} === true, "object <= object")
ok({} <= new Number(34.2) === false, "object <= number object")
ok(new Number(34.2) <= void 0 === false, "number object <= undefined")
ok(new Number(34.2) <= null === false, "number object <= null")
ok(new Number(34.2) <= true === false, "number object <= boolean")
ok(new Number(24.2) <= "3" === false, "number object <= string")
ok(new Number(34.2) <= 73 === true, "number object <= number")
ok(new Number(34.2) <= {} === false, "number object <= object")
ok(new Number(34.2) <= new Number(34.2) === true, "number object <= number object")


// ---------------------------------------------------
// 11 tests: number <= number

ok(NaN <= 1234 === false, 'NaN <= anything')
ok(4312 <= NaN === false, 'anything + NaN')
ok(273 <= 273        === true, 'x <= x')
ok(0 <= -0           === true, '0 <= -0')
ok(-0 <= 0           === true, '-0 <= +0')
ok(Infinity <= 2892  === false, 'inf <= anything')
ok(23278 <= Infinity === true,  'anything <= inf')
ok(233 <= -Infinity  === false, 'anything <= -inf')
ok(-Infinity <= 2323 === true,  '-inf <= anything')
ok(3 <= 4            === true,  '3 <= 4')
ok(4 <= 3            === false, '4 <= 3')


// ---------------------------------------------------
// 6 tests: stwing <= stwing

ok('beans' <= 'beans' === true, 'x <= x (string)')
ok('yarnbard' <= 'yarn' === false, 'x <= y when y is a prefix of x')
ok('thread' <= 'threadbare' === true, 'x <= y when x is a prefix of y')
ok('a' <= 'b' === true, '"a" <= "b"')
ok('aaab' <= 'aaac' === true, "'aaab' <= 'aaac'")
ok('\u00f0' <= '\udf00' === true, "'\\u00f0' <= '\\udf00'")

// ---------------------------------------------------
// 1 test
expr = 1
is(expr <= (expr = 0), false, 'lvalue <= expr modifying the lvalue');


// ===================================================
// 11.8.4 >=
// ===================================================

// 49 tests: type conversion

ok(void 0 >= void 0 === false, "undefined >= undefined")
ok(void 0 >= null === false, "undefined >= null")
ok(void 0 >= true === false, "undefined >= boolean")
ok(void 0 >= "M" === false, "undefined >= string")
ok(void 0 >= 73 === false, "undefined >= number")
ok(void 0 >= {} === false, "undefined >= object")
ok(void 0 >= new Number(34.2) === false, "undefined >= number object")
ok(null >= void 0 === false, "null >= undefined")
ok(null >= null === true, "null >= null")
ok(null >= false === true, "null >= boolean")
ok(null >= "3" === false, "null >= string")
ok(null >= 73 === false, "null >= number")
ok(null >= {} === false, "null >= object")
ok(null >= new Number(34.2) === false, "null >= number object")
ok(true >= void 0 === false, "boolean >= undefined")
ok(true >= null === true, "boolean >= null")
ok(true >= true === true, "boolean >= boolean")
ok(true >= "3" === false, "boolean >= string")
ok(true >= 73 === false, "boolean >= number")
ok(true >= {} === false, "boolean >= object")
ok(true >= new Number(34.2) === false, "boolean >= number object")
ok("O" >= void 0 === false, "string >= undefined")
ok("3" >= null === true, "string >= null")
ok("3" >= true === true, "string >= boolean")
ok("3" >= "3" === true, "string >= string")
ok("8" >= 73 === false, "string >= number")
ok("[p" >= {} === true, "string >= object")
ok("4" >= new Number(34.2) === false, "string >= number object")
ok(73 >= void 0 === false, "number >= undefined")
ok(73 >= null === true, "number >= null")
ok(73 >= true === true, "number >= boolean")
ok(73 >= "8" === true, "number >= string")
ok(73 >= 73 === true, "number >= number")
ok(73 >= {} === false, "number >= object")
ok(73 >= new Number(34.2) === true, "number >= number object")
ok({} >= void 0 === false, "object >= undefined")
ok({} >= null === false, "object >= null")
ok({} >= true === false, "object >= boolean")
ok({} >= "[a" === true, "object >= string")
ok({} >= 73 === false, "object >= number")
ok({} >= {} === true, "object >= object")
ok({} >= new Number(34.2) === false, "object >= number object")
ok(new Number(34.2) >= void 0 === false, "number object >= undefined")
ok(new Number(34.2) >= null === true, "number object >= null")
ok(new Number(34.2) >= true === true, "number object >= boolean")
ok(new Number(34.2) >= "8" === true, "number object >= string")
ok(new Number(34.2) >= 73 === false, "number object >= number")
ok(new Number(34.2) >= {} === false, "number object >= object")
ok(new Number(34.2) >= new Number(34.2) === true, "number object >= number object")


// ---------------------------------------------------
// 11 tests: number >= number

ok(NaN >= 1234 === false, 'NaN >= anything')
ok(4312 >= NaN === false, 'anything + NaN')
ok(273 >= 273        === true, 'x >= x')
ok(0 >= -0           === true, '0 >= -0')
ok(-0 >= 0           === true, '-0 >= +0')
ok(Infinity >= 2892  === true, 'inf >= anything')
ok(23278 >= Infinity === false,  'anything >= inf')
ok(233 >= -Infinity  === true, 'anything >= -inf')
ok(-Infinity >= 2323 === false,  '-inf >= anything')
ok(3 >= 4            === false,  '3 >= 4')
ok(4 >= 3            === true, '4 >= 3')


// ---------------------------------------------------
// 6 tests: yarn >= yarn

ok('beans' >= 'beans' === true, 'x >= x (string)')
ok('yarnbard' >= 'yarn' === true, 'x >= y when y is a prefix of x')
ok('thread' >= 'threadbare' === false, 'x >= y when x is a prefix of y')
ok('a' >= 'b' === false, '"a" >= "b"')
ok('aaab' >= 'aaac' === false, "'aaab' >= 'aaac'")
ok('\u00f0' >= '\udf00' === false, "'\\u00f0' >= '\\udf00'")

// ---------------------------------------------------
// 1 test
expr = 1
is(expr >= (expr = 2), false, 'lvalue >= expr modifying the lvalue');


// ===================================================
// 11.8.6 instanceof (and 15.3.5.3 [[HasInstance]])
// 11 tests
// ===================================================

function tte /* throws TypeError */ (code,testname){
	var error = false
	try { eval(code) }
	catch(up) {
		up instanceof TypeError && error++
	}
	ok(error, testname)
}

tte('"" instanceof ""',     'a instanceof b when b is primitive')
tte('"" instanceof {}',     'a instanceof b when typeof b is object')
ok ( '' instanceof eval === false, 'a instanceof b when a is primitive')
tte('({}) instanceof parseInt',
	'a instanceof b when b has no prototype property')
parseInt.prototype=34;
tte('({}) instanceof parseInt',
	'a instanceof b when b\'s prototype property is primitive')
ok ( Object.prototype instanceof Object === false,
	'a instanceof b when a has no prototype')
ok ( {} instanceof Object === true, 'instanceof (direct instance)')
ok ( new TypeError instanceof Object === true,
	'instanceof with multiple levels of inheritance')
ok ( new TypeError instanceof Error === true,
	'instanceof with one level of inheritance')
ok ( new TypeError instanceof Array === false,
	'instanceof when a isnta b')

expr = []
is(
  expr instanceof (expr = Array), true,
 'lvalue instanceof expr modifying the lvalue'
);


// ===================================================
// 11.8.7 in
// 5 tests
// ===================================================

tte('"oetnuh" in ""', 'a in b whe b is not an object')
ok('eval' in this === true, '"in" when the property exists')
ok('evil' in this === false, '"in" when the property does not exist')
ok('\ud800' in [] === false, '"in" when the property contains a surrogate')

expr = 'length'
is(
  expr in (expr = Object('snat')), true,
 '<lvalue> in <expr modifying the lvalue>'
);
