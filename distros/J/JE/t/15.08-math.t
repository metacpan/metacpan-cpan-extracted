#!perl -T
do './t/jstest.pl' or die __DATA__

function approx(num,str,name) {
 is(num.toString().substring(0,str.toString().length) + typeof num,
    str+'number', name)
}

// ===================================================
// 15.8: Math
// 6 tests
// ===================================================

ok(Math.constructor === Object, 'prototype of Math')
is(Math, '[object Math]', 'default stringification of Math')
is(Object.prototype.toString.call(Math), '[object Math]', 'class of Math')
is(typeof Math, 'object','typeof Math is object, not function')
error=false
try{Math()}
catch(e){error=e}
ok(error instanceof TypeError, 'Math cannot be called as a function')
error = false
try{new Math()}
catch(e){error=e}
ok(error instanceof TypeError, 'Math cannot be called as a constructor')


// ===================================================
// 15.8.1.1: E
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('E'),
	'Math.E is not enumerable')
ok(!delete Math.E, 'Math.E cannot be deleted')
cmp_ok((Math.E = 7, Math.E), '!=', 7,
	'Math.E is read-only')
is(Math.E.toString().substring(0,12) + typeof Math.E, '2.7182818284number',
 'value of E')


// ===================================================
// 15.8.1.2: LN10
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('LN10'),
	'Math.LN10 is not enumerable')
ok(!delete Math.LN10, 'Math.LN10 cannot be deleted')
cmp_ok((Math.LN10 = 7, Math.LN10), '!=', 7,
	'Math.LN10 is read-only')
is(Math.LN10.toString().substring(0,12) + typeof Math.LN10,
 '2.3025850929number', 'value of LN10')


// ===================================================
// 15.8.1.3: LN2
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('LN2'),
	'Math.LN2 is not enumerable')
ok(!delete Math.LN2, 'Math.LN2 cannot be deleted')
cmp_ok((Math.LN2 = 7, Math.LN2), '!=', 7,
	'Math.LN2 is read-only')
is(Math.LN2.toString().substring(0,12) + typeof Math.LN2,
 '0.6931471805number', 'value of LN2')


// ===================================================
// 15.8.1.4: LOG2E
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('LOG2E'),
	'Math.LOG2E is not enumerable')
ok(!delete Math.LOG2E, 'Math.LOG2E cannot be deleted')
cmp_ok((Math.LOG2E = 7, Math.LOG2E), '!=', 7,
	'Math.LOG2E is read-only')
is(Math.LOG2E.toString().substring(0,12) + typeof Math.LOG2E,
 '1.4426950408number', 'value of LOG2E')


// ===================================================
// 15.8.1.5: LOG10E
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('LOG10E'),
	'Math.LOG10E is not enumerable')
ok(!delete Math.LOG10E, 'Math.LOG10E cannot be deleted')
cmp_ok((Math.LOG10E = 7, Math.LOG10E), '!=', 7,
	'Math.LOG10E is read-only')
is(Math.LOG10E.toString().substring(0,12) + typeof Math.LOG10E,
 '0.4342944819number', 'value of LOG10E')


// ===================================================
// 15.8.1.6: PIE
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('PI'),
	'Math.PI is not enumerable')
ok(!delete Math.PI, 'Math.PI cannot be deleted')
cmp_ok((Math.PI = 7, Math.PI), '!=', 7,
	'Math.PI is read-only')
is(Math.PI.toString().substring(0,12) + typeof Math.PI,
 '3.1415926535number', 'value of PI')


// ===================================================
// 15.8.1.7: SQRT1_2
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('SQRT1_2'),
	'Math.SQRT1_2 is not enumerable')
ok(!delete Math.SQRT1_2, 'Math.SQRT1_2 cannot be deleted')
cmp_ok((Math.SQRT1_2 = 7, Math.SQRT1_2), '!=', 7,
	'Math.SQRT1_2 is read-only')
ok(Math.SQRT1_2 === Math.pow(.5,.5), 'value of SQRT1_2')


// ===================================================
// 15.8.1.8: SQRT2
// 4 tests
// ===================================================

ok(!Math.propertyIsEnumerable('SQRT2'),
	'Math.SQRT2 is not enumerable')
ok(!delete Math.SQRT2, 'Math.SQRT2 cannot be deleted')
cmp_ok((Math.SQRT2 = 7, Math.SQRT2), '!=', 7,
	'Math.SQRT2 is read-only')
ok(Math.SQRT2 === Math.pow(2,.5), 'value of SQRT2')


// ===================================================
// 15.8.2.1: abs
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'abs',1)

// 5 tests for type conversion
ok(is_nan(Math.abs(undefined)), 'abs(undefined)')
ok(is_nan(Math.abs({})), 'abs(object)')
ok(Math.abs("-3") === 3, 'abs(string)')
ok(Math.abs(true) === 1, 'abs(bool)')
ok(Math.abs(null) === 0, 'abs(null)')

// 6 tests more
ok(is_nan(Math.abs()), 'abs()')
ok(Math.abs(-5)===5, 'abs(neg)')
ok(Math.abs(7)===7, 'abs(pos)')
is(Math.abs(NaN),NaN,' abs(NaN)')
is(1/Math.abs(-0), 'Infinity', 'abs(-0)')
is(Math.abs(-Infinity),Infinity,'abs(-inf)')


// ===================================================
// 15.8.2.2: acos
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'acos',1)

// 5 tests for type conversion
ok(is_nan(Math.acos(undefined)), 'acos(undefined)')
ok(is_nan(Math.acos({})), 'acos(object)')
approx(Math.acos("-.5"),2.09439510, 'acos(string)')
ok(Math.acos(true) === 0, 'acos(bool)')
approx(Math.acos(null), 1.57079632, 'acos(null)')

// 6 tests more
ok(is_nan(Math.acos()), 'acos()')
approx(Math.acos(.36), '1.202528433358', 'acos(.36)')
is(Math.acos(NaN),NaN,' acos(NaN)')
is(Math.acos(-2),NaN,' acos(<-1)')
is(Math.acos(1.1),NaN,' acos(>1)')
is(1/Math.acos(1), 'Infinity', 'acos(1)')


// ===================================================
// 15.8.2.3: asin
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'asin',1)

// 5 tests for type conversion
ok(is_nan(Math.asin(undefined)), 'asin(undefined)')
ok(is_nan(Math.asin({})), 'asin(object)')
approx(Math.asin("-.5"),-0.523598775598, 'asin(string)')
approx(Math.asin(true),1.57079632679, 'asin(bool)')
is(1/Math.asin(null), Infinity, 'asin(null)')

// 7 tests more
ok(is_nan(Math.asin()), 'asin()')
approx(Math.asin(.36), '0.3682678934366', 'asin(.36)')
is(Math.asin(NaN),NaN,' asin(NaN)')
is(Math.asin(-2),NaN,' asin(<-1)')
is(Math.asin(1.1),NaN,' asin(>1)')
is(1/Math.asin(0), 'Infinity', 'asin(0)')
try{skip("-0 is not supported",1);
    is(1/Math.asin(-0), '-Infinity', 'asin(-0)') }
catch(_){}

// ===================================================
// 15.8.2.4: atan
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'atan',1)

// 5 tests for type conversion
ok(is_nan(Math.atan(undefined)), 'atan(undefined)')
ok(is_nan(Math.atan({})), 'atan(object)')
approx(Math.atan("-.5"),-0.4636476, 'atan(string)')
approx(Math.atan(true),0.785398, 'atan(bool)')
is(1/Math.atan(null), Infinity, 'atan(null)')

// 7 test
ok(is_nan(Math.atan()), 'atan()')
approx(Math.atan(.36), '0.34555558', 'atan(.36)')
is(Math.atan(NaN),NaN,' atan(NaN)')
is(1/Math.atan(0), 'Infinity', 'atan(0)')
try{skip("-0 is not supported",1);
    is(1/Math.atan(-0), '-Infinity', 'atan(-0)') }
catch(_){}
approx(Math.atan(Infinity),1.570796,' atan(inf)')
approx(Math.atan(-Infinity),-1.570796,' atan(-inf)')


// ===================================================
// 15.8.2.5: atan2
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'atan2',2)

// 10 tests for type conversion
ok(is_nan(Math.atan2(2,undefined)), 'atan2(x,undefined)')
ok(is_nan(Math.atan2(undefined,2)), 'atan2(undefined,x)')
ok(is_nan(Math.atan2(2,{})), 'atan2(x,object)')
ok(is_nan(Math.atan2({},2)), 'atan2(object,x)')
approx(Math.atan2(2,"-.5"),1.81577, 'atan2(x,string)')
approx(Math.atan2("-.5",2),-0.24497866, 'atan2(string,x)')
approx(Math.atan2(2,true),1.1071, 'atan2(x,bool)')
approx(Math.atan2(true,2),0.4636476, 'atan2(bool,x)')
approx(Math.atan2(2,null), 1.570796, 'atan2(x,null)')
is(1/Math.atan2(null,2), Infinity, 'atan2(null,x)')

// 30 test
ok(is_nan(Math.atan2()), 'atan2()')
ok(is_nan(Math.atan2(3)), 'atan2 with one argument')
approx(Math.atan2(.36,.4), '0.732815', 'atan2(.36,.4)')
is(Math.atan2(NaN,2),NaN,' atan2(NaN,2)')
is(Math.atan2(2,NaN),NaN,' atan2(2,NaN)')
approx(Math.atan2(7,0),1.570796,' atan2(pos,0)')
approx(Math.atan2(7,-0),1.570796,' atan2(pos,-0)')
is(1/Math.atan2(0,0), Infinity,' atan2(0,0)')
try{skip("-0 is not supported",1);
    approx(Math.atan2(0,-0), '3.14159', 'atan2(0,-0)') }
catch(_){}
approx(Math.atan2(0,-5), '3.14159', 'atan2(0,neg)')
try{skip("-0 is not supported",4);
    is(1/Math.atan2(-0,5), -Infinity, 'atan2(-0,pos)')
    is(1/Math.atan2(-0,0), -Infinity, 'atan2(-0,0)')
    approx(Math.atan2(-0,-0), '-3.14159', 'atan2(-0,-0)')
    approx(Math.atan2(-0,-5), '-3.14159', 'atan2(-0,neg)') }
catch(_){}
approx(Math.atan2(-7,0),-1.570796,' atan2(neg,0)')
approx(Math.atan2(-7,-0),-1.570796,' atan2(neg,-0)')
is(1/Math.atan2(5,Infinity), Infinity,' atan2(pos,inf)')
approx(Math.atan2(5,-Infinity), 3.14159,' atan2(pos,-inf)')
try{skip("-0 is not supported",1);
    is(1/Math.atan2(-5,Infinity), -Infinity, 'atan2(neg,inf)') }
catch(_){}
approx(Math.atan2(-5,-Infinity), -3.14159,' atan2(neg,-inf)')
approx(Math.atan2(Infinity,5),1.570796,' atan2(inf,pos)')
approx(Math.atan2(Infinity,-5),1.570796,' atan2(inf,neg)')
approx(Math.atan2(Infinity,0),1.570796,' atan2(inf,0)')
approx(Math.atan2(-Infinity,5),-1.570796,' atan2(-inf,pos)')
approx(Math.atan2(-Infinity,-5),-1.570796,' atan2(-inf,neg)')
approx(Math.atan2(-Infinity,0),-1.570796,' atan2(-inf,0)')
approx(Math.atan2(Infinity,Infinity),.785398,' atan2(inf,inf)')
approx(Math.atan2(Infinity,-Infinity),2.35619,' atan2(inf,-inf)')
approx(Math.atan2(-Infinity,Infinity),-.785398,' atan2(-inf,inf)')
approx(Math.atan2(-Infinity,-Infinity),-2.35619,' atan2(-inf,-inf)')


// ===================================================
// 15.8.2.6: ceil
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'ceil',1)

// 5 tests for type conversion
ok(is_nan(Math.ceil(undefined)), 'ceil(undefined)')
ok(is_nan(Math.ceil({})), 'ceil(object)')
is(Math.ceil("-1"),-1, 'ceil(string)')
is(Math.ceil(true),1, 'ceil(bool)')
is(1/Math.ceil(null), Infinity, 'ceil(null)')

// 12 test
is(typeof Math.ceil(0), 'number', 'Math.ceil returns number, not object')
ok(is_nan(Math.ceil()), 'ceil()')
is(Math.ceil(56.36), 57, 'ceil(float)')
is(Math.ceil(57), 57, 'ceil(int)')
is(Math.ceil(-56.36), -56, 'ceil(-float)')
is(Math.ceil(-57), -57, 'ceil(-int)')
is(Math.ceil(NaN),NaN,' ceil(NaN)')
is(1/Math.ceil(0), 'Infinity', 'ceil(0)')
try{skip("-0 is not supported",2);
    is(1/Math.ceil(-0), '-Infinity', 'ceil(-0)')
    is(1/Math.ceil(-.5), '-Infinity', 'ceil(-.5)') }
catch(_){}
is(Math.ceil(Infinity),Infinity,' ceil(inf)')
is(Math.ceil(-Infinity),-Infinity,' ceil(-inf)')


// ===================================================
// 15.8.2.7: cos
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'cos',1)

// 5 tests for type conversion
ok(is_nan(Math.cos(undefined)), 'cos(undefined)')
ok(is_nan(Math.cos({})), 'cos(object)')
approx(Math.cos("-2"),-.4161468, 'cos(string)')
approx(Math.cos(true),.5403, 'cos(bool)')
is(Math.cos(null), 1, 'cos(null)')

// 8 test
is(typeof Math.cos(0), 'number', 'Math.cos returns number, not object')
ok(is_nan(Math.cos()), 'cos()')
approx(Math.cos(56.36), .98225, 'cos(float)')
is(Math.cos(NaN),NaN,' cos(NaN)')
is(Math.cos(0), 1, 'cos(0)')
is(Math.cos(-0), 1, 'cos(-0)')
is(Math.cos(Infinity),NaN,' cos(inf)')
is(Math.cos(-Infinity),NaN,' cos(-inf)')


// ===================================================
// 15.8.2.8: exp
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'exp',1)

// 5 tests for type conversion
ok(is_nan(Math.exp(undefined)), 'exp(undefined)')
ok(is_nan(Math.exp({})), 'exp(object)')
approx(Math.exp("-2"),.135335, 'exp(string)')
approx(Math.exp(true),2.71828, 'exp(bool)')
is(Math.exp(null), 1, 'exp(null)')

// 8 test
is(typeof Math.exp(0), 'number', 'Math.exp returns number, not object')
ok(is_nan(Math.exp()), 'exp()')
approx(Math.exp(6.36), 578.246, 'exp(float)')
is(Math.exp(NaN),NaN,' exp(NaN)')
is(Math.exp(0), 1, 'exp(0)')
is(Math.exp(-0), 1, 'exp(-0)')
is(Math.exp(Infinity),Infinity,' exp(inf)')
is(1/Math.exp(-Infinity),Infinity,' exp(-inf)')


// ===================================================
// 15.8.2.9: floor
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'floor',1)

// 5 tests for type conversion
ok(is_nan(Math.floor(undefined)), 'floor(undefined)')
ok(is_nan(Math.floor({})), 'floor(object)')
is(Math.floor("-1"),-1, 'floor(string)')
is(Math.floor(true),1, 'floor(bool)')
is(1/Math.floor(null), Infinity, 'floor(null)')

// 12 test
is(typeof Math.floor(0), 'number', 'Math.floor returns number, not object')
ok(is_nan(Math.floor()), 'floor()')
is(Math.floor(56.36), 56, 'floor(float)')
is(Math.floor(57), 57, 'floor(int)')
is(Math.floor(-56.36), -57, 'floor(-float)')
is(Math.floor(-57), -57, 'floor(-int)')
is(Math.floor(NaN),NaN,' floor(NaN)')
is(1/Math.floor(0), 'Infinity', 'floor(0)')
try{skip("-0 is not supported",1);
    is(1/Math.floor(-0), '-Infinity', 'floor(-0)') }
catch(_){}
is(1/Math.floor(0.5), 'Infinity', 'floor(.5)')
is(Math.floor(Infinity),Infinity,' floor(inf)')
is(Math.floor(-Infinity),-Infinity,' floor(-inf)')


// ===================================================
// 15.8.2.10: log
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'log',1)

// 5 tests for type conversion
ok(is_nan(Math.log(undefined)), 'log(undefined)')
ok(is_nan(Math.log({})), 'log(object)')
ok(is_nan(Math.log("-2")), 'log(string)')
is(1/Math.log(true),Infinity, 'log(bool)')
is(Math.log(null), -Infinity, 'log(null)')

// 10 test
is(typeof Math.log(0), 'number', 'Math.log returns number, not object')
ok(is_nan(Math.log()), 'log()')
approx(Math.log(6.36), '1.8500', 'log(pos)')
ok(is_nan(Math.log(-6.36)), 'log(neg)')
is(Math.log(NaN),NaN,' log(NaN)')
is(Math.log(0), -Infinity, 'log(0)')
is(Math.log(-0), -Infinity, 'log(-0)')
is(1/Math.log(1),Infinity, 'log(1)')
is(Math.log(Infinity),Infinity,' log(inf)')
is(Math.log(-Infinity),NaN,' log(-inf)')


// ===================================================
// 15.8.2.11: max
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'max',2)

// 5 tests for type conversion
ok(is_nan(Math.max(undefined)), 'max(undefined)')
ok(is_nan(Math.max({})), 'max(object)')
is((Math.max("-2","3")), 3, 'max(string)')
is(Math.max(true,false),1, 'max(bool)')
is(Math.max(null,-1), 0, 'max(null)')

// 4 test
ok(Math.max() === -Infinity, 'argless max')
ok(is_nan(Math.max(3,NaN,4)), 'max with a nan arg')
ok(Math.max(1,3,-50,2) === 3, 'max with just numbers')
try{ skip("negative zero is not supported",1)
     is(1/Math.max(-0,0), Infinity, 'max considers 0 greater than -0') }
catch(_){}


// ===================================================
// 15.8.2.12: min
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'min',2)

// 5 tests for type conversion
ok(is_nan(Math.min(undefined)), 'min(undefined)')
ok(is_nan(Math.min({})), 'min(object)')
is((Math.min("-2","3")), -2, 'min(string)')
is(Math.min(true,false),0, 'min(bool)')
is(Math.min(null,11), 0, 'min(null)')

// 4 test
ok(Math.min() === Infinity, 'argless min')
ok(is_nan(Math.min(3,NaN,4)), 'min with a nan arg')
ok(Math.min(1,3,-50,2) === -50, 'min with just numbers')
try{ skip("negative zero is not supported",1)
     is(1/Math.min(-0,0), -Infinity, 'min considers 0 greater than -0') }
catch(_){}


// ===================================================
// 15.8.2.13: pow
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'pow',2)

// 10 tests for type conversion
ok(is_nan(Math.pow(2,undefined)), 'pow(x,undefined)')
ok(is_nan(Math.pow(undefined,2)), 'pow(undefined,x)')
ok(is_nan(Math.pow(2,{})), 'pow(x,object)')
ok(is_nan(Math.pow({},2)), 'pow(object,x)')
approx(Math.pow(2,"-.5"),.70710678, 'pow(x,string)')
is(Math.pow("-.5",2),.25, 'pow(string,x)')
is(Math.pow(2,true),2, 'pow(x,bool)')
is(Math.pow(true,2),1, 'pow(bool,x)')
is(Math.pow(2,null), 1, 'pow(x,null)')
is(Math.pow(null,2), 0, 'pow(null,x)')

// 39 test
is(typeof Math.pow(0,0), 'number', 'Math.pow returns number, not object')
ok(is_nan(Math.pow()), 'pow()')
ok(is_nan(Math.pow(3)), 'pow with one argument')
approx(Math.pow(.36,.4), '0.6645398', 'pow(.36,.4)')
is(Math.pow(2,NaN),NaN,' pow(2,NaN)')
is(Math.pow(7,0),1,' pow(pos,0)')
is(Math.pow(NaN,0),1,' pow(NaN,0)')
is(Math.pow(7,-0),1,' pow(pos,-0)')
is(Math.pow(NaN,-0),1,' pow(NaN,-0)')
is(Math.pow(NaN,32),NaN,' pow(NaN,-0)')
is(Math.pow(23,Infinity), Infinity,' pow(>1,inf)')
is(Math.pow(-23,Infinity), Infinity,' pow(<-1,inf)')
is(1/Math.pow(23,-Infinity), Infinity,' pow(>1,-inf)')
is(1/Math.pow(-23,-Infinity), Infinity,' pow(<-1,-inf)')
is(Math.pow(1,Infinity), NaN,' pow(1,inf)')
is(Math.pow(1,-Infinity), NaN,' pow(1,-inf)')
is(1/Math.pow(.23,Infinity), Infinity,' pow(between 0 and 1,inf)')
is(1/Math.pow(-.23,Infinity), Infinity,' pow(between -1 and 0,inf)')
is(Math.pow(.23,-Infinity), Infinity,' pow(between 0 and 1,-inf)')
is(Math.pow(-.23,-Infinity), Infinity,' pow(between -1 and 0,-inf)')
is(Math.pow(Infinity,2), Infinity,' pow(inf,pos)')
is(1/Math.pow(Infinity,-2), Infinity,' pow(inf,neg)')
is(Math.pow(-Infinity,3), -Infinity,' pow(-inf,odd)')
is(Math.pow(-Infinity,2), Infinity,' pow(-inf,even)')
is(Math.pow(-Infinity,2.3), Infinity,' pow(-inf,float)')
try{skip("-0 is not supported",1);
 is(1/Math.pow(-Infinity,-3),-Infinity,'pow(-inf,-odd)')
}catch(_){}
is(1/Math.pow(-Infinity,-2), Infinity,' pow(-inf,-even)')
is(1/Math.pow(-Infinity,-2.3), Infinity,' pow(-inf,-float)')
is(1/Math.pow(0,5), 'Infinity', 'pow(0,pos)')
is(Math.pow(0,-5), 'Infinity', 'pow(0,neg)')
is(Math.pow(0,-4), 'Infinity', 'pow(0,-even)')
try{skip("-0 is not supported",1);
    is(1/Math.pow(-0,5), -Infinity, 'pow(-0,odd)')
}catch(_){}
is(1/Math.pow(-0,4),Infinity,' pow(-0,even)')
is(1/Math.pow(-0,4.3),Infinity,' pow(-0,float)')
try{skip("-0 is not supported",1);
 is(Math.pow(-0,-3),-Infinity,' pow(-0,-odd)')
}catch(_){}
is(Math.pow(-0,-4), Infinity,' pow(-0,-even)')
is(Math.pow(-0,-4.3), Infinity,' pow(-0,-float)')
is(Math.pow(-5,3.4), NaN,' pow(neg finite,float)')
is(Math.pow(-5,-3.4), NaN,' pow(neg finite,-float)')


// ===================================================
// 15.8.2.14: random
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'random',0)

// 3 tests
is(typeof Math.random(),'number','Math.random returns number, not object')
cmp_ok(Math.random(), '>=', 0, 'Math.random() >= 0')
cmp_ok(Math.random(), '<', 1, 'Math.random() < 1')

// ===================================================
// 15.8.2.15: round
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'round',1)

// 5 tests for type conversion
ok(is_nan(Math.round(undefined)), 'round(undefined)')
ok(is_nan(Math.round({})), 'round(object)')
is(Math.round("-1"),-1, 'round(string)')
is(Math.round(true),1, 'round(bool)')
is(1/Math.round(null), Infinity, 'round(null)')

// 17 test
is(typeof Math.round(0), 'number', 'Math.round returns number, not object')
ok(is_nan(Math.round()), 'round()')
is(Math.round(56.36), 56, 'round(float) rounding down')
is(Math.round(56.51), 57, 'round(float) rounding up')
is(Math.round(56.5), 57, 'round(float) rounding up (halfway point)')
is(Math.round(57), 57, 'round(int)')
is(Math.round(-56.51), -57, 'round(-float) rounding down')
is(Math.round(-56.36), -56, 'round(-float) rounding up')
is(Math.round(-56.5), -56, 'round(-float) rounding up (halfway point)')
is(Math.round(-57), -57, 'round(-int)')
is(Math.round(NaN),NaN,' round(NaN)')
is(1/Math.round(0), 'Infinity', 'round(0)')
try{skip("-0 is not supported",2);
    is(1/Math.round(-0), '-Infinity', 'round(-0)')
    is(1/Math.round(-.5), '-Infinity', 'round(-.5)') }
catch(_){}
is(1/Math.round(0.4), 'Infinity', 'round(between 0 and .5)')
is(Math.round(Infinity),Infinity,' round(inf)')
is(Math.round(-Infinity),-Infinity,' round(-inf)')

// ===================================================
// 15.8.2.16: sin
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'sin',1)

// 5 tests for type conversion
ok(is_nan(Math.sin(undefined)), 'sin(undefined)')
ok(is_nan(Math.sin({})), 'sin(object)')
approx(Math.sin("-2"),-.909297, 'sin(string)')
approx(Math.sin(true),.84147, 'sin(bool)')
is(Math.sin(null), 0, 'sin(null)')

// 8 test
is(typeof Math.sin(0), 'number', 'Math.sin returns number, not object')
ok(is_nan(Math.sin()), 'sin()')
approx(Math.sin(56.36), -.18755, 'sin(float)')
is(Math.sin(NaN),NaN,' sin(NaN)')
is(1/Math.sin(0), Infinity, 'sin(0)')
try{skip("-0 is not supported",1);
 is(1/Math.sin(-0), -Infinity, 'sin(-0)')
}catch(_){}
is(Math.sin(Infinity),NaN,' sin(inf)')
is(Math.sin(-Infinity),NaN,' sin(-inf)')


// ===================================================
// 15.8.2.17: sqrt
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'sqrt',1)

// 5 tests for type conversion
ok(is_nan(Math.sqrt(undefined)), 'sqrt(undefined)')
ok(is_nan(Math.sqrt({})), 'sqrt(object)')
approx(Math.sqrt("2"),1.4142, 'sqrt(string)')
is(Math.sqrt(true),1, 'sqrt(bool)')
is(Math.sqrt(null), 0, 'sqrt(null)')

// 9 tests
is(typeof Math.sqrt(0), 'number', 'Math.sqrt returns number, not object')
ok(is_nan(Math.sqrt()), 'sqrt()')
approx(Math.sqrt(56.36), 7.50732975, 'sqrt(float)')
is(Math.sqrt(NaN),NaN,' sqrt(NaN)')
is(Math.sqrt(-32),NaN,' sqrt(neg)')
is(1/Math.sqrt(0), Infinity, 'sqrt(0)')
try{skip("-0 is not supported",1);
 is(1/Math.sqrt(-0), -Infinity, 'sqrt(-0)')
}catch(_){}
is(Math.sqrt(Infinity),Infinity,' sqrt(inf)')
is(Math.sqrt(-Infinity),NaN,' sqrt(-inf)')


// ===================================================
// 15.8.2.18: tan
// ===================================================

// 10 tests
method_boilerplate_tests(Math,'tan',1)

// 5 tests for type conversion
ok(is_nan(Math.tan(undefined)), 'tan(undefined)')
ok(is_nan(Math.tan({})), 'tan(object)')
approx(Math.tan("-2"),2.1850, 'tan(string)')
approx(Math.tan(true),1.5574, 'tan(bool)')
is(Math.tan(null), 0, 'tan(null)')

// 8 test
is(typeof Math.tan(0), 'number', 'Math.tan returns number, not object')
ok(is_nan(Math.tan()), 'tan()')
approx(Math.tan(56.36), -.1909386799, 'tan(float)')
is(Math.tan(NaN),NaN,' tan(NaN)')
is(1/Math.tan(0), Infinity, 'tan(0)')
try{skip("-0 is not supported",1);
 is(1/Math.tan(-0), -Infinity, 'tan(-0)')
}catch(_){}
is(Math.tan(Infinity),NaN,' tan(inf)')
is(Math.tan(-Infinity),NaN,' tan(-inf)')
