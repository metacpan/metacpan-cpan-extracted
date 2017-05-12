#!perl -T
do './t/jstest.pl' or die __DATA__

function is_nan(n){ // checks to see whether the number is *really* NaN
                    // & not something which converts to NaN when numified
	return n!=n
}

// ===================================================
// 15.1.2.1: eval
// 16 tests
// ===================================================

is(typeof eval, 'function', 'typeof eval');
is(Object.prototype.toString.apply(eval), '[object Function]',
	'class of eval')
ok(Function.prototype.isPrototypeOf(eval), 'eval\'s prototype')
$catched = false;
try{ new eval } catch(e) { $catched = e }
ok($catched, 'new eval fails')
ok(!('prototype' in eval), 'eval has no prototype property')
ok(eval.length === 1, 'eval.length')
ok(!eval.propertyIsEnumerable('length'), 'eval.length is not enumerable')
ok(!delete eval.length, 'eval.length cannot be deleted')
is((eval.length++, eval.length), 1, 'eval.length is read-only')

ok(eval('3+3; 4+4;') === 8,      'successful eval with return value')
ok(eval('var x')     === void 0, 'successful eval with no return value')

$catched = false;
try { eval('throw void 0') }
catch(phrase) {	phrase === undefined && ($catched = true) }
ok($catched, 'eval(\'throw\') (see whether errors propagate)')

$catched = false;
try { eval('Y@#%*^@#%*(^$') }
catch(phrase) {	phrase instanceof SyntaxError && ($catched = true) }
ok($catched, 'eval(invalid syntax)')

ok(eval(0) === 0, 'eval(number)')
ok(eval(new String('this isn\'t really a string')) instanceof String,
	'eval(new String)')

ok(eval() === undefined, 'argless eval()')

// ===================================================
// 15.1.2.2: parseInt
// ===================================================

// 10 tests (boilerplate stuff for built-ins)
is(typeof parseInt, 'function', 'typeof parseInt');
is(Object.prototype.toString.apply(parseInt), '[object Function]',
	'class of parseInt')
ok(Function.prototype.isPrototypeOf(parseInt), 'parseInt\'s prototype')
$catched = false;
try{ new parseInt } catch(e) { $catched = e }
ok($catched, 'new parseInt fails')
ok(!('prototype' in parseInt), 'parseInt has no prototype property')
ok(parseInt.length === 2, 'parseInt.length')
ok(!parseInt.propertyIsEnumerable('length'),
	'parseInt.length is not enumerable')
ok(!delete parseInt.length, 'parseInt.length cannot be deleted')
is((parseInt.length++, parseInt.length), 2, 'parseInt.length is read-only')
ok(is_nan(parseInt()), 'parseInt() w/o args')


bad_radices = [ // 14 elems
	2147483648,
	3000000000,
	4000000000.23,
	6442450944,
	6442450946.74,
	-1,
	-32.5,
	-5000000000,
	-4294967298.479,
	-6442450942,
	-6442450943.674,
	-6442450944,
	37,
	true,
]
nought_radices = [ // 11 elems
	undefined,
	null,
	false,
	'a',
	{},
	NaN,
	+0,
	-0,
	Infinity,
	-Infinity,
	4294967296,
]
// We’ll use '2' for 2 to test type conversion at the same time.
other_radices = [ // 34 useful elems
	0,0,0, // placeholders
	3,
	4.6,
	4294967301,     // 5
	4294967302.479, // 6
	-4294967289,    // 7
	-4294967288.23, // 8
	-8589934583,    // 9
	-8589934582.74, // 10
	11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,
	30,31,32,33,34,35,36,
]
// There are 60 test radices altogether

/* parseInt(undefined) */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(undefined, bad_radices[i])),
		'parseInt(undefined, ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(undefined, nought_radices[i])),
		'parseInt(undefined, ' + nought_radices[i] + ')')
ok(is_nan(parseInt(undefined, '2')), 'parseInt(undefined,"2")')
for(i = 3; i< 31; ++i) {
	ok(is_nan(parseInt(undefined, other_radices[i])),
		'parseInt(undefined, ' + other_radices[i] + ')')
}
ok(parseInt(void 0, 31) === 26231474015353, 'parseInt(undefined, 31)')
ok(parseInt(void 0, 32) === 33790067563981, 'parseInt(undefined, 32)')
ok(parseInt(void 0, 33) === 43189838176003, 'parseInt(undefined, 33)')
ok(parseInt(void 0, 34) === 54802593533125, 'parseInt(undefined, 34)')
ok(parseInt(void 0, 35) === 69060721616053, 'parseInt(undefined, 35)')
ok(parseInt(void 0, 36) === 86464843759093, 'parseInt(undefined, 36)')

/* parseInt(null) */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(null, bad_radices[i])),
		'parseInt(null, ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(null, nought_radices[i])),
		'parseInt(null, ' + nought_radices[i] + ')')
ok(is_nan(parseInt(null, '2')), 'parseInt(null,"2")')
for(i = 3; i<=23; ++i) {
	ok(is_nan(parseInt(null, other_radices[i])),
		'parseInt(null, ' + other_radices[i] + ')')
}
for(i = 24; i< 31; ++i) {
	ok(parseInt(null, other_radices[i]) === 23,
		'parseInt(null, ' + other_radices[i] + ')')
}
ok(parseInt(null, 31) === 714695, 'parseInt(null, 31)')
ok(parseInt(null, 32) === 785077, 'parseInt(null, 32)')
ok(parseInt(null, 33) === 859935, 'parseInt(null, 33)')
ok(parseInt(null, 34) === 939407, 'parseInt(null, 34)')
ok(parseInt(null, 35) === 1023631, 'parseInt(null, 35)')
ok(parseInt(null, 36) === 1112745, 'parseInt(null, 36)')

/* parseInt(true) */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(true, bad_radices[i])),
		'parseInt(true, ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(true, nought_radices[i])),
		'parseInt(true, ' + nought_radices[i] + ')')
ok(is_nan(parseInt(true, '2')), 'parseInt(true,"2")')
for(i = 3; i<=29; ++i) {
	ok(is_nan(parseInt(true, other_radices[i])),
		'parseInt(true, ' + other_radices[i] + ')')
}
ok(parseInt(true, 30) === 897, 'parseInt(true, 30)')
ok(parseInt(true, 31) === 890830, 'parseInt(true, 31)')
ok(parseInt(true, 32) === 978894, 'parseInt(true, 32)')
ok(parseInt(true, 33) === 1072580, 'parseInt(true, 33)')
ok(parseInt(true, 34) === 1172062, 'parseInt(true, 34)')
ok(parseInt(true, 35) === 1277514, 'parseInt(true, 35)')
ok(parseInt(true, 36) === 1389110, 'parseInt(true, 36)')

/* parseInt(false) */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(false, bad_radices[i])),
		'parseInt(false, ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(false, nought_radices[i])),
		'parseInt(false, ' + nought_radices[i] + ')')
ok(is_nan(parseInt(false, '2')), 'parseInt(false,"2")')
for(i = 3; i<=15; ++i) {
	ok(is_nan(parseInt(false, other_radices[i])),
		'parseInt(false, ' + other_radices[i] + ')')
}
ok(parseInt(false, 16) === 250, 'parseInt(false, 16)')
ok(parseInt(false, 17) === 265, 'parseInt(false, 17)')
ok(parseInt(false, 18) === 280, 'parseInt(false, 18)')
ok(parseInt(false, 19) === 295, 'parseInt(false, 19)')
ok(parseInt(false, 20) === 310, 'parseInt(false, 20)')
ok(parseInt(false, 21) === 325, 'parseInt(false, 21)')
ok(parseInt(false, 22) === 7501, 'parseInt(false, 22)')
ok(parseInt(false, 23) === 8186, 'parseInt(false, 23)')
ok(parseInt(false, 24) === 8901, 'parseInt(false, 24)')
ok(parseInt(false, 25) === 9646, 'parseInt(false, 25)')
ok(parseInt(false, 26) === 10421, 'parseInt(false, 26)')
ok(parseInt(false, 27) === 11226, 'parseInt(false, 27)')
ok(parseInt(false, 28) === 12061, 'parseInt(false, 28)')
ok(parseInt(false, 29) === 10871592, 'parseInt(false, 29)')
ok(parseInt(false, 30) === 12439754, 'parseInt(false, 30)')
ok(parseInt(false, 31) === 14171788, 'parseInt(false, 31)')
ok(parseInt(false, 32) === 16078734, 'parseInt(false, 32)')
ok(parseInt(false, 33) === 18171992, 'parseInt(false, 33)')
ok(parseInt(false, 34) === 20463322, 'parseInt(false, 34)')
ok(parseInt(false, 35) === 22964844, 'parseInt(false, 35)')
ok(parseInt(false, 36) === 25689038, 'parseInt(false, 36)')

/* parseInt(num) when num contains no digits that the
 * radix accepts */
// 22 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(73.2, bad_radices[i])),
		'parseInt(73.2, ' + bad_radices[i] + ')')
ok(is_nan(parseInt(73.2, '2')), 'parseInt(73.2,"2")')
for(i = 3; i<=9; ++i) {
	ok(is_nan(parseInt(93.2, other_radices[i])),
		'parseInt(93.2, ' + other_radices[i] + ')')
}

/* parseInt(num) when num has trailing bad chars */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(10.2, bad_radices[i])),
		'parseInt(10.2, ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(10.2, nought_radices[i]) === 10,
		'parseInt(10.2, ' + nought_radices[i] + ')')
ok(parseInt(10.2, '2') === 2, 'parseInt(10.2,"2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(10.2, other_radices[i]) === i,
		'parseInt(10.2, ' + other_radices[i] + ')')
}

/* parseInt(num) when num is already an integer compatible
 * with the radix */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(10, bad_radices[i])),
		'parseInt(10, ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(10, nought_radices[i]) === 10,
		'parseInt(10, ' + nought_radices[i] + ')')
ok(parseInt(10, '2') === 2, 'parseInt(10,"2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(10, other_radices[i]) === i,
		'parseInt(10, ' + other_radices[i] + ')')
}

/* parseInt(num) when num is negative and contains no digits that the
 * radix accepts */
// 22 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(-73.2, bad_radices[i])),
		'parseInt(-73.2, ' + bad_radices[i] + ')')
ok(is_nan(parseInt(-73.2, '2')), 'parseInt(-73.2,"2")')
for(i = 3; i<=9; ++i) {
	ok(is_nan(parseInt(-93.2, other_radices[i])),
		'parseInt(-93.2, ' + other_radices[i] + ')')
}

/* parseInt(num) when num is negative and has trailing bad chars */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(-10.2, bad_radices[i])),
		'parseInt(-10.2, ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(-10.2, nought_radices[i]) === -10,
		'parseInt(-10.2, ' + nought_radices[i] + ')')
ok(parseInt(-10.2, '2') === -2, 'parseInt(10.2,"2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(-10.2, other_radices[i]) === -i,
		'parseInt(-10.2, ' + other_radices[i] + ')')
}

/* parseInt(num) when num is negative and is already an integer compatible
 * with the radix */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(-10, bad_radices[i])),
		'parseInt(-10, ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(-10, nought_radices[i]) === -10,
		'parseInt(-10, ' + nought_radices[i] + ')')
ok(parseInt(-10, '2') === -2, 'parseInt(10,"2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(-10, other_radices[i]) === -i,
		'parseInt(-10, ' + other_radices[i] + ')')
}

/* parseInt(str) when str consists solely of whitespace */
// 60 tests

ws = '\t\v\f \u00a0\u2002';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(ws, bad_radices[i])),
		'parseInt(ws, ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(ws, nought_radices[i])),
		'parseInt(ws, ' + nought_radices[i] + ')')
ok(is_nan(parseInt(ws, '2')), 'parseInt(ws,"2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt(ws, other_radices[i])),
		'parseInt(ws, ' + other_radices[i] + ')')
}

/* parseInt(str) when str has initial whitespace but no digits immediately
 * thereafter */
// 60 tests

ws = '\t\v\f \u00a0\u2002';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(ws + '.8', bad_radices[i])),
		'parseInt(ws + ".8", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(ws + '.8', nought_radices[i])),
		'parseInt(ws + ".8", ' + nought_radices[i] + ')')
ok(is_nan(parseInt(ws + '.8', '2')), 'parseInt(ws + ".8","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt(ws + '.8', other_radices[i])),
		'parseInt(ws + ".8", ' + other_radices[i] + ')')
}

/* parseInt(str) when str has initial whitespace, 0x, and trail-
 * ing bad chars */
// 60 tests

str = '\t\v\f \u00a0\u20020x10@'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "0x10@", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === 16,
		'parseInt(ws + "0x10@", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt(ws + "0x10@","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? 16 : 0),
		'parseInt(ws + "0x10@", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === 38182, 'parseInt(ws + "0x10@",34)')
ok(parseInt(str, 35) === 40460, 'parseInt(ws + "0x10@",35)')
ok(parseInt(str, 36) === 42804, 'parseInt(ws + "0x10@",36)')

/* parseInt(str) when str has initial whitespace and contains invalid
 * chars, but no 0x */
// 60 tests

str = '\t\v\f \u00a0\u200210!';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "10!", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == 10,
		'parseInt(ws + "10!", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == 2, 'parseInt(ws + "10!","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == i,
		'parseInt(ws + "10!", ' + other_radices[i] + ')')
}

/* parseInt(str) when str has initial whitespace and 0X */
// 60 tests

str = '\t\v\f \u00a0\u20020X10'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "0X10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === 16,
		'parseInt(ws + "0X10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt(ws + "0X10","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? 16 : 0),
		'parseInt(ws + "0X10", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === 38182, 'parseInt(ws + "0X10",34)')
ok(parseInt(str, 35) === 40460, 'parseInt(ws + "0X10",35)')
ok(parseInt(str, 36) === 42804, 'parseInt(ws + "0X10",36)')

/* parseInt(str) — ws followed by plain old integer */
// 60 tests

str = '\t\v\f \u00a0\u200210';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == 10,
		'parseInt(ws + "10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == 2, 'parseInt(ws + "10","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == i,
		'parseInt(ws + "10", ' + other_radices[i] + ')')
}

/* parseInt('+str') when str consists solely of whitespace */
// 60 tests

str = '\t\v\f \u00a0\u2002+';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "+", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(str, nought_radices[i])),
		'parseInt(ws + "+", ' + nought_radices[i] + ')')
ok(is_nan(parseInt(str, '2')), 'parseInt(ws + "+","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt(str, other_radices[i])),
		'parseInt(ws + "+", ' + other_radices[i] + ')')
}

/* parseInt('+str') when str has initial whitespace but no digits
 * immediately thereafter */
// 60 tests

ws = '\t\v\f \u00a0\u2002';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(ws + '+.8', bad_radices[i])),
		'parseInt(ws + "+.8", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(ws + '+.8', nought_radices[i])),
		'parseInt(ws + "+.8", ' + nought_radices[i] + ')')
ok(is_nan(parseInt(ws + '+.8', '2')), 'parseInt(ws + "+.8","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt(ws + '+.8', other_radices[i])),
		'parseInt(ws + "+.8", ' + other_radices[i] + ')')
}

/* parseInt('+str') when str has initial whitespace, 0x, and trail-
 * ing bad chars */
// 60 tests

str = '\t\v\f \u00a0\u2002+0x10@'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "+0x10@", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === 16,
		'parseInt(ws + "+0x10@", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt(ws + "+0x10@","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? 16 : 0),
		'parseInt(ws + "+0x10@", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === 38182, 'parseInt(ws + "+0x10@",34)')
ok(parseInt(str, 35) === 40460, 'parseInt(ws + "+0x10@",35)')
ok(parseInt(str, 36) === 42804, 'parseInt(ws + "+0x10@",36)')

/* parseInt('+str') when str has initial whitespace and contains invalid
 * chars, but no 0x */
// 60 tests

str = '\t\v\f \u00a0\u2002+10!';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "+10!", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == 10,
		'parseInt(ws + "+10!", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == 2, 'parseInt(ws + "+10!","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == i,
		'parseInt(ws + "+10!", ' + other_radices[i] + ')')
}

/* parseInt('+str') when str has initial whitespace and +0X */
// 60 tests

str = '\t\v\f \u00a0\u2002+0X10'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "+0X10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === 16,
		'parseInt(ws + "+0X10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt(ws + "+0X10","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? 16 : 0),
		'parseInt(ws + "+0X10", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === 38182, 'parseInt(ws + "+0X10",34)')
ok(parseInt(str, 35) === 40460, 'parseInt(ws + "+0X10",35)')
ok(parseInt(str, 36) === 42804, 'parseInt(ws + "+0X10",36)')

/* parseInt('+str') — ws followed by plain old integer */
// 60 tests

str = '\t\v\f \u00a0\u2002+10';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "+10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == 10,
		'parseInt(ws + "+10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == 2, 'parseInt(ws + "+10","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == i,
		'parseInt(ws + "+10", ' + other_radices[i] + ')')
}

/* parseInt('-str') when str consists solely of whitespace */
// 60 tests

str = '\t\v\f \u00a0\u2002-';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "-", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(str, nought_radices[i])),
		'parseInt(ws + "-", ' + nought_radices[i] + ')')
ok(is_nan(parseInt(str, '2')), 'parseInt(ws + "-","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt(str, other_radices[i])),
		'parseInt(ws + "-", ' + other_radices[i] + ')')
}

/* parseInt('-str') when str has initial whitespace but no digits
 * immediately thereafter */
// 60 tests

ws = '\t\v\f \u00a0\u2002';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(ws + '-.8', bad_radices[i])),
		'parseInt(ws + "-.8", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(ws + '-.8', nought_radices[i])),
		'parseInt(ws + "-.8", ' + nought_radices[i] + ')')
ok(is_nan(parseInt(ws + '+.8', '2')), 'parseInt(ws + "+.8","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt(ws + '-.8', other_radices[i])),
		'parseInt(ws + "-.8", ' + other_radices[i] + ')')
}

/* parseInt('-str') when str has initial whitespace, 0x, and trail-
 * ing bad chars */
// 60 tests

str = '\t\v\f \u00a0\u2002-0x10@'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "-0x10@", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === -16,
		'parseInt(ws + "-0x10@", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt(ws + "-0x10@","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? -16 : 0),
		'parseInt(ws + "-0x10@", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === -38182, 'parseInt(ws + "-0x10@",34)')
ok(parseInt(str, 35) === -40460, 'parseInt(ws + "-0x10@",35)')
ok(parseInt(str, 36) === -42804, 'parseInt(ws + "-0x10@",36)')

/* parseInt('-str') when str has initial whitespace and contains invalid
 * chars, but no 0x */
// 60 tests

str = '\t\v\f \u00a0\u2002-10!';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "-10!", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == -10,
		'parseInt(ws + "-10!", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == -2, 'parseInt(ws + "-10!","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == -i,
		'parseInt(ws + "-10!", ' + other_radices[i] + ')')
}

/* parseInt('-str') when str has initial whitespace and +0X */
// 60 tests

str = '\t\v\f \u00a0\u2002-0X10'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "-0X10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === -16,
		'parseInt(ws + "-0X10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt(ws + "-0X10","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? -16 : 0),
		'parseInt(ws + "-0X10", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === -38182, 'parseInt(ws + "-0X10",34)')
ok(parseInt(str, 35) === -40460, 'parseInt(ws + "-0X10",35)')
ok(parseInt(str, 36) === -42804, 'parseInt(ws + "-0X10",36)')

/* parseInt('-str') — ws followed by plain old integer */
// 60 tests

str = '\t\v\f \u00a0\u2002-10';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt(ws + "-10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == -10,
		'parseInt(ws + "-10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == -2, 'parseInt(ws + "-10","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == -i,
		'parseInt(ws + "-10", ' + other_radices[i] + ')')
}

/* parseInt(str) when str is blank */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt('', bad_radices[i])),
		'parseInt("", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt("", nought_radices[i])),
		'parseInt("", ' + nought_radices[i] + ')')
ok(is_nan(parseInt("", '2')), 'parseInt("","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt("", other_radices[i])),
		'parseInt("", ' + other_radices[i] + ')')
}

/* parseInt(str) when str begins with bad chars */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt('.8', bad_radices[i])),
		'parseInt(".8", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt('.8', nought_radices[i])),
		'parseInt(".8", ' + nought_radices[i] + ')')
ok(is_nan(parseInt('.8', '2')), 'parseInt(".8","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt('.8', other_radices[i])),
		'parseInt(".8", ' + other_radices[i] + ')')
}

/* parseInt(str) when str has 0x and trail-
 * ing bad chars */
// 60 tests

str = '0x10@'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("0x10@", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === 16,
		'parseInt("0x10@", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt("0x10@","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? 16 : 0),
		'parseInt("0x10@", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === 38182, 'parseInt("0x10@",34)')
ok(parseInt(str, 35) === 40460, 'parseInt("0x10@",35)')
ok(parseInt(str, 36) === 42804, 'parseInt("0x10@",36)')

/* parseInt(str) when str contains invalid
 * chars, but no 0x */
// 60 tests

str = '10!';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("10!", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == 10,
		'parseInt("10!", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == 2, 'parseInt("10!","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == i,
		'parseInt("10!", ' + other_radices[i] + ')')
}

/* parseInt(str) when str has 0X */
// 60 tests

str = '0X10'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("0X10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === 16,
		'parseInt("0X10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt("0X10","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? 16 : 0),
		'parseInt("0X10", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === 38182, 'parseInt("0X10",34)')
ok(parseInt(str, 35) === 40460, 'parseInt("0X10",35)')
ok(parseInt(str, 36) === 42804, 'parseInt("0X10",36)')

/* parseInt(str) — plain old integer */
// 60 tests

str = '10';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == 10,
		'parseInt("10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == 2, 'parseInt("10","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == i,
		'parseInt("10", ' + other_radices[i] + ')')
}

/* parseInt('+') */
// 60 tests

str = '+';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("+", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(str, nought_radices[i])),
		'parseInt("+", ' + nought_radices[i] + ')')
ok(is_nan(parseInt(str, '2')), 'parseInt("+","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt(str, other_radices[i])),
		'parseInt("+", ' + other_radices[i] + ')')
}

/* parseInt('+bad chars') */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt('+.8', bad_radices[i])),
		'parseInt("+.8", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt('+.8', nought_radices[i])),
		'parseInt("+.8", ' + nought_radices[i] + ')')
ok(is_nan(parseInt('+.8', '2')), 'parseInt("+.8","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt('+.8', other_radices[i])),
		'parseInt("+.8", ' + other_radices[i] + ')')
}

/* parseInt('+str') when str has 0x and trail-
 * ing bad chars */
// 60 tests

str = '+0x10@'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("+0x10@", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === 16,
		'parseInt("+0x10@", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt("+0x10@","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? 16 : 0),
		'parseInt("+0x10@", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === 38182, 'parseInt("+0x10@",34)')
ok(parseInt(str, 35) === 40460, 'parseInt("+0x10@",35)')
ok(parseInt(str, 36) === 42804, 'parseInt("+0x10@",36)')

/* parseInt('+str') when str contains invalid
 * chars, but no 0x */
// 60 tests

str = '+10!';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("+10!", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == 10,
		'parseInt("+10!", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == 2, 'parseInt("+10!","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == i,
		'parseInt("+10!", ' + other_radices[i] + ')')
}

/* parseInt('+str') when str has +0X */
// 60 tests

str = '+0X10'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("+0X10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === 16,
		'parseInt("+0X10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt("+0X10","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? 16 : 0),
		'parseInt("+0X10", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === 38182, 'parseInt("+0X10",34)')
ok(parseInt(str, 35) === 40460, 'parseInt("+0X10",35)')
ok(parseInt(str, 36) === 42804, 'parseInt("+0X10",36)')

/* parseInt('+str') — plain old integer */
// 60 tests

str = '+10';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("+10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == 10,
		'parseInt("+10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == 2, 'parseInt("+10","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == i,
		'parseInt("+10", ' + other_radices[i] + ')')
}

/* parseInt('-') */
// 60 tests

str = '-';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("-", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt(str, nought_radices[i])),
		'parseInt("-", ' + nought_radices[i] + ')')
ok(is_nan(parseInt(str, '2')), 'parseInt("-","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt(str, other_radices[i])),
		'parseInt("-", ' + other_radices[i] + ')')
}

/* parseInt('-bad chars') */
// 60 tests

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt('-.8', bad_radices[i])),
		'parseInt("-.8", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(is_nan(parseInt('-.8', nought_radices[i])),
		'parseInt("-.8", ' + nought_radices[i] + ')')
ok(is_nan(parseInt('+.8', '2')), 'parseInt("+.8","2")')
for(i = 3; i<=36; ++i) {
	ok(is_nan(parseInt('-.8', other_radices[i])),
		'parseInt("-.8", ' + other_radices[i] + ')')
}

/* parseInt('-str') when str has 0x and trail-
 * ing bad chars */
// 60 tests

str = '-0x10@'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("-0x10@", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === -16,
		'parseInt("-0x10@", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt("-0x10@","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? -16 : 0),
		'parseInt("-0x10@", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === -38182, 'parseInt("-0x10@",34)')
ok(parseInt(str, 35) === -40460, 'parseInt("-0x10@",35)')
ok(parseInt(str, 36) === -42804, 'parseInt("-0x10@",36)')

/* parseInt('-str') when str has contains invalid
 * chars, but no 0x */
// 60 tests

str = '-10!';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("-10!", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == -10,
		'parseInt("-10!", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == -2, 'parseInt("-10!","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == -i,
		'parseInt("-10!", ' + other_radices[i] + ')')
}

/* parseInt('-str') when str has 0X */
// 60 tests

str = '-0X10'

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("-0X10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) === -16,
		'parseInt("-0X10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') === 0, 'parseInt("-0X10","2")')
for(i = 3; i<=33; ++i) {
	ok(parseInt(str, other_radices[i]) === (i == 16 ? -16 : 0),
		'parseInt("-0X10", ' + other_radices[i] + ')')
}
ok(parseInt(str, 34) === -38182, 'parseInt("-0X10",34)')
ok(parseInt(str, 35) === -40460, 'parseInt("-0X10",35)')
ok(parseInt(str, 36) === -42804, 'parseInt("-0X10",36)')

/* parseInt('-str') — plain old integer */
// 60 tests

str = '-10';

for(i = 0; i< bad_radices.length; ++i)
	ok(is_nan(parseInt(str, bad_radices[i])),
		'parseInt("-10", ' + bad_radices[i] + ')')
for(i = 0; i< nought_radices.length; ++i)
	ok(parseInt(str, nought_radices[i]) == -10,
		'parseInt("-10", ' + nought_radices[i] + ')')
ok(parseInt(str, '2') == -2, 'parseInt("-10","2")')
for(i = 3; i<=36; ++i) {
	ok(parseInt(str, other_radices[i]) == -i,
		'parseInt("-10", ' + other_radices[i] + ')')
}

/* parseInt(object) */
// 1 test

ok(parseInt(new String("100"), 23) === 23*23, 'parseInt(object)') 

/* parseInt(surrogate) */
// 1 test

result = 0;
try{result = parseInt('\ud800')}
catch(e){result = e}
is(result, 'NaN', 'parseInt(surrogate)')

// ===================================================
// 15.1.2.3: parseFloat
// ===================================================

// 10 tests (boilerplate stuff for built-ins)
is(typeof parseFloat, 'function', 'typeof parseFloat');
is(Object.prototype.toString.apply(parseFloat), '[object Function]',
	'class of parseFloat')
ok(Function.prototype.isPrototypeOf(parseFloat), 'parseFloat\'s prototype')
$catched = false;
try{ new parseFloat } catch(e) { $catched = e }
ok($catched, 'new parseFloat fails')
ok(!('prototype' in parseFloat), 'parseFloat has no prototype property')
ok(parseFloat.length === 1, 'parseFloat.length')
ok(!parseFloat.propertyIsEnumerable('length'),
	'parseFloat.length is not enumerable')
ok(!delete parseFloat.length, 'parseFloat.length cannot be deleted')
is((parseFloat.length++, parseFloat.length), 1,
	'parseFloat.length is read-only')
ok(is_nan(parseFloat()), 'parseFloat() w/o args')

// 7 tests
ok(is_nan(parseFloat(undefined)), 'parseFloat(undefined)')
ok(is_nan(parseFloat(null     )), 'parseFloat(null)')
ok(is_nan(parseFloat(true     )), 'parseFloat(true)')
ok(is_nan(parseFloat(false    )), 'parseFloat(false)')
ok(parseFloat(0        ) === 0, 'parseFloat(0)')
ok(parseFloat(Infinity)===Infinity,  'parseFloat(Infinity)')
ok(is_nan(parseFloat({})),         'parseFloat({})')

// 685 tests (57 * 12 + 1)
pf_tests = [
	// num lit.  value     test name  
	['0',          0,      'digit 0'],
	['1',          1,      'digit 1'],
	['2',          2,      'digit 2'],
	['3',          3,      'digit 3'],
	['4',          4,      'digit 4'],
	['5',          5,      'digit 5'],
	['6',          6,      'digit 6'],
	['7',          7,      'digit 7'],
	['8',          8,      'digit 8'],
	['9',          9,      'digit 9'],
	['10',        10,      'multiple digits'],
	['100',      100,      'multiple digits'],
	['1000',    1000,      'multiple digits'],
	['10.5',      10.5,    'decimal point'],
	['10.',       10,      'trailing decimal point'],
	['0.7',         .7,    '"0." followed by digit'],
	['0.',         0,      '"0."'],
	['.6',          .6,    'leading decimal point'],
	['.6E6',       6e5,    'leading decimal point + E digit'],
	['.6E-6',      6e-7,   'leading decimal point + E-digit'],
	['.6E+6',      6e5,    'leading decimal point + E+digit'],
	['.6e6',       6e5,    'leading decimal point + e digit'],
	['.6e-6',      6e-7,   'leading decimal point + e-digit'],
	['.6e+6',      6e5,    'leading decimal point + e+digit'],
	['0E0',        0,      'integer with E'],
	['10E0',      10,      'integer with E'],
	['13e2',    1300,      'integer with e digit'],
	['13.e2',   1300,      'trailing decimal point with e digit'],
	['13.0e2',  1300,      'decimal point with e digit'],
	['13e+2',   1300,      'integer with e+digit'],
	['13.e+2',  1300,      'trailing decimal point with e+digit'],
	['13.0e+2', 1300,      'decimal point with e+digit'],
	['13e-2',       .13,   'integer with e-digit'],
	['13.e-2',      .13,   'trailing decimal point with e-digit'],
	['13.0e-2',     .13,   'decimal point with e-digit'],
	['13E2',    1300,      'integer with E digit'],
	['13.E2',   1300,      'trailing decimal point with E digit'],
	['13.0E2',  1300,      'decimal point with E digit'],
	['13E+2',   1300,      'integer with E+digit'],
	['13.E+2',  1300,      'trailing decimal point with E+digit'],
	['13.0E+2', 1300,      'decimal point with E+digit'],
	['13E-2',       .13,   'integer with E-digit'],
	['13.E-2',      .13,   'trailing decimal point with E-digit'],
	['13.0E-2',     .13,   'decimal point with E-digit'],
	['0.4e3',    400,      '0.digit with e digit'],
	['0.4e+3',   400,      '0.digit with e+digit'],
	['0.4e-3',      .0004, '0.digit with e-digit'],
	['0.4E3',    400,      '0.digit with E digit'],
	['0.4E+3',   400,      '0.digit with E+digit'],
	['0.4E-3',      .0004, '0.digit with E-digit'],
	['0.e3',       0,      '0. with e digit'],
	['0.e+3',      0,      '0. with e+digit'],
	['0.e-3',      0,      '0. with e-digit'],
	['0.E3',       0,      '0. with E digit'],
	['0.E+3',      0,      '0. with E+digit'],
	['0.E-3',      0,      '0. with E-digit'],
	['Infinity', Infinity, 'Infinity'],
]

for(var i = 0; i<pf_tests.length;++i)
	ok(parseFloat(pf_tests[i][0])===pf_tests[i][1],
		'parseFloat: ' + pf_tests[i][2]),
	ok(parseFloat('\t\f \u00a0\u2002' + pf_tests[i][0])
			===pf_tests[i][1],
		'parseFloat: ws ' + pf_tests[i][2]),
	ok(parseFloat(pf_tests[i][0] + '@!#@')===pf_tests[i][1],
		'parseFloat: ' + pf_tests[i][2] + ' + gibberish'),
	ok(parseFloat('\t\f \u00a0\u2002' + pf_tests[i][0] + '@!#@')
			===pf_tests[i][1],
		'parseFloat: ws ' + pf_tests[i][2] + ' + gibberish'),
	ok(parseFloat('+'+pf_tests[i][0])===pf_tests[i][1],
		'parseFloat: + ' + pf_tests[i][2]),
	ok(parseFloat('\t\f \u00a0\u2002+' + pf_tests[i][0])
			===pf_tests[i][1],
		'parseFloat: ws + ' + pf_tests[i][2]),
	ok(parseFloat('+'+pf_tests[i][0] + '@!#@')===pf_tests[i][1],
		'parseFloat: + ' + pf_tests[i][2] + ' + gibberish'),
	ok(parseFloat('\t\f \u00a0\u2002+' + pf_tests[i][0] + '@!#@')
			===pf_tests[i][1],
		'parseFloat: ws + ' + pf_tests[i][2] + ' + gibberish'),
	ok(parseFloat('-'+pf_tests[i][0])===-pf_tests[i][1],
		'parseFloat: + ' + pf_tests[i][2]),
	ok(parseFloat('\t\f \u00a0\u2002-' + pf_tests[i][0])
			===-pf_tests[i][1],
		'parseFloat: ws - ' + pf_tests[i][2]),
	ok(parseFloat('-'+pf_tests[i][0] + '@!#@')===-pf_tests[i][1],
		'parseFloat: - ' + pf_tests[i][2] + ' + gibberish'),
	ok(parseFloat('\t\f \u00a0\u2002-' + pf_tests[i][0] + '@!#@')
			===-pf_tests[i][1],
		'parseFloat: ws - ' + pf_tests[i][2] + ' + gibberish')
ok(is_nan(parseFloat('nonsens')), 'parseFloat(gibberish)')

/* parseInt(surrogate) */
// 1 test

result = 0;
try{result = parseFloat('\ud800')}
catch(e){result = e}
is(result, 'NaN', 'parseFloat(surrogate)')

// ===================================================
// 15.1.2.4: isNaN
// ===================================================

// 10 tests (boilerplate stuff for built-ins)
is(typeof isNaN, 'function', 'typeof isNaN');
is(Object.prototype.toString.apply(isNaN), '[object Function]',
	'class of isNaN')
ok(Function.prototype.isPrototypeOf(isNaN), 'isNaN\'s prototype')
$catched = false;
try{ new isNaN } catch(e) { $catched = e }
ok($catched, 'new isNaN fails')
ok(!('prototype' in isNaN), 'isNaN has no prototype property')
ok(isNaN.length === 1, 'isNaN.length')
ok(!isNaN.propertyIsEnumerable('length'),
	'isNaN.length is not enumerable')
ok(!delete isNaN.length, 'isNaN.length cannot be deleted')
is((isNaN.length++, isNaN.length), 1,
	'isNaN.length is read-only')
ok(isNaN() === true, 'isNaN() w/o args')

// 10 tests
ok(isNaN(undefined) === true, 'isNaN(undefined)')
ok(isNaN(null     ) === false, 'isNaN(null)')
ok(isNaN(true     ) === false, 'isNaN(true)')
ok(isNaN(false    ) === false, 'isNaN(false)')
ok(isNaN(0        ) === false, 'isNaN(0)')
ok(isNaN(Infinity)===false,  'isNaN(Infinity)')
ok(isNaN(NaN)===true,  'isNaN(NaN)')
ok(isNaN(' astring')===true,  'isNaN(string)')
ok(isNaN('33')===false,  'isNaN(numeric string)')
ok(isNaN({})===true,         'isNaN({})')

// ===================================================
// 15.1.2.5: isFinite
// ===================================================

// 10 tests (boilerplate stuff for built-ins)
is(typeof isFinite, 'function', 'typeof isFinite');
is(Object.prototype.toString.apply(isFinite), '[object Function]',
	'class of isFinite')
ok(Function.prototype.isPrototypeOf(isFinite), 'isFinite\'s prototype')
$catched = false;
try{ new isFinite } catch(e) { $catched = e }
ok($catched, 'new isFinite fails')
ok(!('prototype' in isFinite), 'isFinite has no prototype property')
ok(isFinite.length === 1, 'isFinite.length')
ok(!isFinite.propertyIsEnumerable('length'),
	'isFinite.length is not enumerable')
ok(!delete isFinite.length, 'isFinite.length cannot be deleted')
is((isFinite.length++, isFinite.length), 1,
	'isFinite.length is read-only')
ok(isFinite()===false, 'isFinite() w/o args')

// 11 tests
ok(isFinite(undefined) === false, 'isFinite(undefined)')
ok(isFinite(null     ) === true, 'isFinite(null)')
ok(isFinite(true     ) === true, 'isFinite(true)')
ok(isFinite(false    ) === true, 'isFinite(false)')
ok(isFinite(0        ) === true, 'isFinite(0)')
ok(isFinite(Infinity)===false,  'isFinite(Infinity)')
ok(isFinite(-Infinity)===false,  'isFinite(-Infinity)')
ok(isFinite(NaN)===false,  'isFinite(NaN)')
ok(isFinite(' astring')===false,  'isFinite(string)')
ok(isFinite('33')===true,  'isFinite(numeric string)')
ok(isFinite({})===false,         'isFinite({})')

