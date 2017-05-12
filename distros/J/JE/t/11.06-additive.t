#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 105;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-4: Bind some functions
isa_ok $j->new_function( ok  => \&ok   ), 'JE::Object::Function';
isa_ok $j->new_function( diag => \&diag ), 'JE::Object::Function';
isa_ok $j->new_function( skip  => \&skip ), 'JE::Object::Function';
$j->new_function(is=>\&is);


# JS tests
defined $j->eval( <<'--end--' ) or die;

function is_nan(n) { // sees whether something is *identical* to NaN
	return typeof n == 'number' && isNaN(n);
}

// ===================================================
// 11.6.1 +
// ===================================================

/* Tests 5-53: +'s type conversion (also takes care of string + string) */

ok(is_nan(void 0 + void 0),                 "undefined + undefined")
ok(is_nan(void 0 + null),                      "undefined + null")
ok(is_nan(void 0 + true),                         "undefined + boolean")
ok(void 0 + 'string' === 'undefinedstring',         "undefined + string")
ok(is_nan(void 0 + 73),                              "undefined + number")
ok(void 0 + {}       === 'undefined[object Object]', "undefined + object")
ok(is_nan(void 0 + new Number(34.2)),          "undefined + number object")
ok(is_nan(null   + void 0),                    "null + undefined")
ok(null +  null             ===  0,            "null + null")
ok(null +  true             ===  1,             "null + boolean")
ok(null + 'string'          === 'nullstring',     "null + string")
ok(null +  73               ===  73,                "null + number")
ok(null +  {}               === 'null[object Object]', "null + object")
ok(null +  new Number(34.2) ===  34.2,              "null + number object")
ok(is_nan(true + void 0),                           "boolean + undefined")
ok( true +  null             ===  1,                "boolean + null")
ok( true +  true             ===  2,                "boolean + boolean")
ok( true + 'string'          === 'truestring',       "boolean + string")
ok( true +  73               ===  74,                 "boolean + number")
ok( true +  {}               === 'true[object Object]', "boolean + object")
ok( true +  new Number(34.2) ===  35.2,          "boolean + number object")
ok('string' +  void 0        === 'stringundefined', "string + undefined")
ok('string' +  null          === 'stringnull',        "string + null")
ok('string' +  true          === 'stringtrue',         "string + boolean")
ok('string' + 'string'       === 'stringstring',       "string + string")
ok('string' +  73            === 'string73',            "string + number")
ok('string' +  {}           === 'string[object Object]', "string + object")
ok('string' + new Number(34.2) === 'string34.2',  "string + number object")
ok(is_nan(73 + void 0),                           "number + undefined")
ok( 73      +  null              === 73,          "number + null")
ok( 73      +  true               === 74,          "number + boolean")
ok( 73      + 'string'            === '73string',   "number + string")
ok( 73      +  73                ===  146,            "number + number")
ok( 73      +  {}               === '73[object Object]', "number + object")
ok( 73      +  new Number(34.2) ===  107.2,       "number + number object")
ok( {}      +  void 0 === '[object Object]undefined', "object + undefined")
ok( {}      +  null   === '[object Object]null',       "object + null")
ok( {}      +  true   === '[object Object]true',        "object + boolean")
ok( {}      + 'string' === '[object Object]string',     "object + string")
ok( {}      +  73    === '[object Object]73',           "object + number")
ok( {}      +  {}  === '[object Object][object Object]', "object + object")
ok( {}      + new Number(34.2) === '[object Object]34.2',
	"object + number object")
ok(is_nan(new Number(34.2) + void 0), "number object + undefined")
ok(new Number(34.2) +  null    ===  34.2,        "number object + null")
ok(new Number(34.2) +  true    ===  35.2,        "number object + boolean")
ok(new Number(34.2) + 'string' === '34.2string', "number object + string")
ok(new Number(34.2) +  73        === 107.2,      "number object + number")
ok(new Number(34.2) +  {}           === '34.2[object Object]',
	"number object + object")
ok(new Number(34.2) +  new Number(34.2) === 68.4,
	"number object + number object")


// ---------------------------------------------------
/* Tests 54-73: number + number (11.6.3) */

ok(is_nan( NaN      + 322),             'NaN + anything')
ok(is_nan( 2389     + NaN),             'anything + NaN')
ok(is_nan( NaN      + NaN),             'NaN + NaN')
ok(is_nan(-Infinity +  Infinity),       '-inf + inf')
ok(is_nan( Infinity + -Infinity),       'inf + -inf')
ok( Infinity +  Infinity ===  Infinity, 'inf + inf')
ok(-Infinity + -Infinity === -Infinity, '-inf + -inf')
ok( Infinity +  3.54     ===  Infinity, 'inf + +finite')
ok(-Infinity + -3.54     === -Infinity, '-inf + -finite')
ok(-Infinity +  3.54     === -Infinity, '-inf + +finite')
ok( Infinity + -3.54     ===  Infinity, 'inf + -finite')
// ~~~ need to add tests for ±0 + ±0
ok( 0        +  3        ===  3,        '+0 + +')
ok(-0        +  3        ===  3,        '-0 + +')
ok( 0        + -3        === -3,        '+0 + -')
ok(-0        + -3        === -3,        '+0 + +')
ok( 75       + -75       ===  0,        'x + -x')
ok(-75       +  75       ===  0,        '-x + x')
// ~~~ need to confirm that addition is IEEE754-compliant and
//     supports gradual underflow, whatever that is
ok(3+4.8 === 7.8, '3+4.8')

try{
	skip('not yet IEEE754-compliant', 2);
	ok( 9e+307 +  9e+307 ===  Infinity, 'positive overflow with +')
	ok(-9e+307 + -9e+307 === -Infinity, 'negative overflow with +')
}catch(y){}

// ---------------------------------------------------
/* Test 74 */

expr = 1
is(expr + (expr = 2), 3, 'lvalue + expr modifying the lvalue');


// ===================================================
// 11.6.2 -
// ===================================================

/* Tests 75-84: -'s type conversion */

ok(is_nan(void 0 - 2), 'undefined - number')
ok(null   - 3 === -3,  'null - number')
ok(true   - 2 === -1,  'boolean - number')
ok('3.00' - 4 === -1,  'string - number')
ok(is_nan({} - 2),     'object - number')
ok(is_nan(2 - void 0), 'number - undefined')
ok(3 -  null  ===  3,  'number - null')
ok(3 -  true  ===  2,  'number - boolean')
ok(3 - '4.00' === -1,  'number - string')
ok(is_nan(2 - {}),     'number - object')


// ---------------------------------------------------
/* Tests 85-104: number - number (11.6.3) */

ok(is_nan( NaN      - 322),             'NaN - anything')
ok(is_nan( 2389     - NaN),             'anything - NaN')
ok(is_nan( NaN      - NaN),             'NaN - NaN')
ok(is_nan(-Infinity - -Infinity),       '-inf - inf')
ok(is_nan( Infinity -  Infinity),       'inf - -inf')
ok( Infinity - -Infinity ===  Infinity, 'inf - inf')
ok(-Infinity -  Infinity === -Infinity, '-inf - -inf')
ok( Infinity - -3.54     ===  Infinity, 'inf - -finite')
ok(-Infinity -  3.54     === -Infinity, '-inf - -finite')
ok(-Infinity - -3.54     === -Infinity, '-inf - -finite')
ok( Infinity -  3.54     ===  Infinity, 'inf - -finite')
// ~~~ need to add tests for ±0 - ±0
ok( 0        - -3        ===  3,        '-0 - -')
ok(-0        - -3        ===  3,        '-0 - -')
ok( 0        -  3        === -3,        '-0 - -')
ok(-0        -  3        === -3,        '-0 - -')
ok( 75       -  75       ===  0,        'x - -x')
ok(-75       - -75       ===  0,        '-x - x')
// ~~~ need to confirm that addition is IEEE754-compliant and
//     supports gradual underflow, whatever that is
ok(3-4.8 === -1.8, '3-4.8')

try{
	skip('not yet IEEE754-compliant', 2);
	// these test fail only on some 64-bit systems; I'm not sure why
	ok( 9e+307 - -9e+307 ===  Infinity, 'positive overflow with -')
	ok(-9e+307 -  9e+307 === -Infinity, 'negative overflow with -')
}catch(y){}

// ---------------------------------------------------
/* Test 105 */

expr = 1
is(expr - (expr = 2), -1, 'lvalue - expr modifying the lvalue');

--end--
