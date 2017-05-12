#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 108;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-4: Bind some functions
isa_ok $j->new_function( ok  => \&ok   ), 'JE::Object::Function';
isa_ok $j->new_function( diag => \&diag ), 'JE::Object::Function';
isa_ok $j->new_function( skip  => \&skip ), 'JE::Object::Function';
$j->new_function( is  => \&is );


# JS tests
defined $j->eval( <<'--end--' ) or die;

// ===================================================
// 11.5.1 *
// ===================================================

/* Tests 5-14: *'s type conversion */

ok(isNaN(void 0 * 2), 'undefined * number')
ok(null   * 3 ===  0, 'null * number')
ok(true   * 3 ===  3, 'boolean * number')
ok('3.00' * 4 === 12, 'string * number')
ok(isNaN({} * 2),     'object * number')
ok(isNaN(2 * void 0), 'number * undefined')
ok(3 *  null  ===  0, 'number * null')
ok(3 *  true  ===  3, 'number * boolean')
ok(4 * '3.00' === 12, 'number * string')
ok(isNaN(2 * {}),     'number * object')


// ---------------------------------------------------
/* Tests 15-36: number * number */

ok(isNaN(NaN  * 322),                   'NaN * anything')
ok(isNaN(2389 * NaN),                   'anything * NaN')
ok(isNaN(NaN  * NaN),                   'NaN * NaN')
ok( 1 *  3 ===  3,                      '+ * +')
ok(-1 *  3 === -3,                      '- * +')
ok( 1 * -3 === -3,                      '+ * -')
ok(-1 * -3 ===  3,                      '+ * +')
// ~~~ need to add tests for ±Infinity * -0
ok(isNaN( Infinity * 0),                'inf * 0')
ok(isNaN(-Infinity * 0),                '-inf * 0')
ok( Infinity *  Infinity ===  Infinity, 'inf * inf')
ok(-Infinity * -Infinity ===  Infinity, '-inf * -inf')
ok(-Infinity *  Infinity === -Infinity, '-inf * inf')
ok( Infinity * -Infinity === -Infinity, 'inf * -inf')
ok( Infinity *  3.54     ===  Infinity, 'inf * +finite')
ok(-Infinity * -3.54     ===  Infinity, '-inf * -finite')
ok(-Infinity *  3.54     === -Infinity, '-inf * +finite')
ok( Infinity * -3.54     === -Infinity, 'inf * -finite')
// ~~~ need to confirm that multiplication is IEEE754-compliant and
//     supports gradual underflow, whatever that is
ok(3*4.8 === 14.4, '3*4.8')

try{
	skip('not yet IEEE754-compliant', 4);
	ok( 9e+300 * 9e+300 ===  Infinity, 'positive overflow with *')
	ok(-9e+300 * 9e+300 === -Infinity, 'negative overflow with *')
	ok( 9e-300 * 9e-300 ===  0,        'positive underflow with *')
	ok(-9e-300 * 9e-300 ===  0,        'negative underflow with *')
}catch(y){}

// ---------------------------------------------------
/* Test 37 */
expr = 1
is(expr * (expr = 2), 2, 'lvalue * expr modifying the lvalue');


// ===================================================
// 11.5.2 /
// ===================================================

/* Tests 38-47: /'s type conversion */

ok(isNaN(void 0 / 2),       'undefined / number')
ok(null   / 3 ===  0,       'null / number')
ok(true   / 2 === .5,       'boolean / number')
ok('3.00' / 4 === .75,      'string / number')
ok(isNaN({} / 2),           'object / number')
ok(isNaN(2 / void 0),       'number / undefined')
ok(3 /  null  === Infinity, 'number / null')
ok(3 /  true  ===  3,       'number / boolean')
ok(3 / '4.00' === .75,      'number / string')
ok(isNaN(2 / {}),           'number / object')


// ---------------------------------------------------
/* Tests 48-78: number / number */

// The tests that use '=== -0' are equivalent to '=== 0' in JS. If I ever
// get round to implementing -0, I need to come up with a way to test for
// it.

ok(isNaN(NaN  / 322),               'NaN / anything')
ok(isNaN(2389 / NaN),               'anything / NaN')
ok(isNaN(NaN  / NaN),               'NaN / NaN')
ok( 1 /  2 ===  .5,                 '+ / +')
ok(-1 /  2 === -.5,                 '- / +')
ok( 1 / -2 === -.5,                 '+ / -')
ok(-1 / -2 ===  .5,                 '+ / +')
ok(isNaN( Infinity /  Infinity),    'inf / inf')
ok(isNaN(-Infinity / -Infinity),    '-inf / -inf')
ok(isNaN(-Infinity /  Infinity),    '-inf / inf')
ok(isNaN( Infinity / -Infinity),    'inf / -inf')
// ~~~ need to add tests for ±Infinity / -0 and ±0 / ±0
ok( Infinity /  0    ===  Infinity, 'inf / 0')
ok(-Infinity /  0    === -Infinity, '-inf / 0')
ok( Infinity /  3.54 ===  Infinity, 'inf / +finite')
ok(-Infinity / -3.54 ===  Infinity, '-inf / -finite')
ok(-Infinity /  3.54 === -Infinity, '-inf / +finite')
ok( Infinity / -3.54 === -Infinity, 'inf / -finite')
ok( 3.54 /  Infinity ===  0,        '+finite / inf')
ok(-3.54 / -Infinity ===  0,        '-finity / -inf')
ok( 3.54 / -Infinity === -0,        '+finite / -inf')
ok(-3.54 /  Infinity === -0,        '-finite / inf')
ok(isNaN(0 / 0),                    '0 / 0')
ok( 0    /  3.54     ===  0,        '0 / +')
ok( 0    / -3.54     === -0,        '0 / -')
ok( 3.54 /  0        ===  Infinity, '+finite / 0')
ok(-3.54 /  0        === -Infinity, '-finite / 0')
// ~~~ need to confirm that divison is IEEE754-compliant and
//     supports gradual underflow, whatever that is
ok(3/4.8 === .625, '3/4.8')

try{
	skip('not yet IEEE754-compliant', 4);
	// these test fail only on some 64-bit systems; I'm not sure why
	ok( 9e+300 / 9e-300 ===  Infinity, 'positive overflow with /')
	ok(-9e+300 / 9e-300 === -Infinity, 'negative overflow with /')
	ok( 9e-300 / 9e+300 ===  0,        'positive underflow with /')
	ok(-9e-300 / 9e+300 ===  0,        'negative underflow with /')
}catch(y){}

// ---------------------------------------------------
/* Test 79 */
expr = 4
is(expr / (expr = 2), 2, 'lvalue / expr modifying the lvalue');


// ===================================================
// 11.5.3 %
// ===================================================

/* Tests 70-89: %'s type conversion */

ok(isNaN(void 0 % 2), 'undefined % number')
ok(null   % 3 === 0,  'null % number')
ok(true   % 2 === 1,  'boolean % number')
ok('3.00' % 4 === 3,  'string % number')
ok(isNaN({} % 2),     'object % number')
ok(isNaN(2 % void 0), 'number % undefined')
ok(isNaN(3 % null),   'number % null')
ok(3 %  true  === 0,  'number % boolean')
ok(3 % '4.00' === 3,  'number % string')
ok(isNaN(2 % {}),     'number % object')


// ---------------------------------------------------
/* Tests 90-107: number % number */

ok(isNaN(NaN  % 322),               'NaN % anything')
ok(isNaN(2389 % NaN),               'anything % NaN')
ok(isNaN(NaN  % NaN),               'NaN % NaN')
ok( 12.5 %  5 ===  2.5,             '+ % +')
ok(-12.5 %  5 === -2.5,             '- % +')
ok( 12.5 % -5 ===  2.5,             '+ % -')
ok(-12.5 % -5 === -2.5,             '+ % +')
ok(isNaN( Infinity % 354),          'inf % anything')
ok(isNaN(-Infinity % 222),          '-inf % anything')
ok(isNaN( 23892    % 0),            'anything % 0')
ok(isNaN( Infinity % 0),            'inf % 0')
ok(isNaN(-Infinity % 0),            '-inf % 0')
ok( 3.54 %  Infinity ===  3.54,     '+finite % inf')
ok(-3.54 % -Infinity === -3.54,     '-finite % -inf')
ok( 3.54 % -Infinity ===  3.54,     '+finite % -inf')
ok(-3.54 %  Infinity === -3.54,     '-finite % inf')
ok( 0    %  3.54     ===  0,        '0 % +')
ok(-0    % -3.54     === -0,        '0 % -')

// ---------------------------------------------------
/* Test 108 */
expr = 4
is(expr % (expr = 3), 1, 'lvalue % expr modifying the lvalue');

--end--
