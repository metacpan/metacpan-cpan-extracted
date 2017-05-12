#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 74;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );


$j->prop(global => $j); 

# Run JS tests

my $line = __LINE__+3; # If I put this on the next line, it gives the last
                       # line of the here-doc (or something like that).
defined $j->eval( <<'--end--', __FILE__, $line ) or die;

// ===================================================
// 11.1.1 this (not that)
// ===================================================

/* Tests 4-7 */

ok(global === this, '\'this\' keyword in global code')
eval("ok(global === this, '\\'this\\' keyword in global-eval code')")
obj = { f: function() {
	ok(this === obj, '\'this\' keyword in function code')
	eval("ok(this === obj, '\\'this\\' keyword in function-eval code')"
	)
} }
obj.f()


// ===================================================
// 11.1.2 Identifiers
// ===================================================
// (identifier resolution is defined in 10.1.4)

/* Test 8 */

var error
try {
	NaN = 333
	eval('NaN = 323'),
	pfpf = 3289
	eval('onetoh = 389')
	function(a) {
		tht =3 
		a=  3
		eval('thteoe = 3; a = 1')
	}()
}
catch(e) { error = true }
ok(!error, 'The result of evalling an identifier is always an lvalue')


// ===================================================
// 11.1.3 Array literals
// ===================================================

/* Tests 9-60 */

a = []
ok(a.length === 0,                               '[]')
a = [,]
ok(a.length === 1 && !('0' in a),                '[,]')
a = [, ,]
ok(a.length === 2 && !('0' in a) && !('1' in a), '[, ,]')
a = [1]
ok(a.length === 1 && a[0] === 1,                 '[ expr ]')
a = [1,2]
ok(a.length === 2 && a[0] === 1 && a[1] === 2,   '[ expr, expr ]')
a = [1, , 2]
ok(a.length === 3 && a[0] === 1 && !('1' in a) && a[2] === 2,
	'[ expr, , expr ]')
a = [1, ,, 2]
ok(a.length === 4 && a[0] === 1 && !('1' in a) && !('2' in a) &&
   a[3]     === 2,                              '[ expr, ,, expr ]')
a = [, 1]
ok(a.length === 2 && !('0' in a) && a[1] === 1, '[ , expr ]')
a = [, 1, 2]
ok(a.length === 3 && !('0' in a) && a[1] === 1 && a[2] === 2,
	'[ , expr, expr ]')
a = [, 1, , 2]
ok(a.length === 4 && !('0' in a) && a[1] === 1 && !('2' in a) &&
   a[3]     === 2, '[ , expr, , expr ]')
a = [, 1, ,, 2]
ok(a.length === 5 && !('0' in a) && a[1] === 1 && !('2' in a) &&
   !('3' in a)    && a[4] === 2, '[ , expr, ,, expr ]')
a = [,, 1]
ok(a.length === 3 && !('0' in a) && !('1' in a) && a[2] === 1,
	'[ ,, expr ]')
a = [,, 1, 2]
ok(a.length === 4 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   a[3]     === 2, '[ ,, expr, expr ]')
a = [,, 1, , 2]
ok(a.length === 5 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   !('3' in a)    && a[4] === 2, '[ ,, expr, , expr ]')
a = [,, 1, ,, 2]
ok(a.length === 6 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   !('3' in a)    && !('4' in a) && a[5] === 2, '[ ,, expr, ,, expr ]')
a = [1,]
ok(a.length === 1 && a[0] === 1,                '[ expr, ]')
a = [1, 2,]
ok(a.length === 2 && a[0] === 1 && a[1] === 2,  '[ expr, expr, ]')
a = [1, , 2,]
ok(a.length === 3 && a[0] === 1 && !('1' in a) && a[2] === 2,
	'[ expr, , expr, ]')
a = [1, ,, 2,]
ok(a.length === 4 && a[0] === 1 && !('1' in a) && !('2' in a) &&
   a[3]     === 2,                              '[ expr, ,, expr, ]')
a = [, 1,]
ok(a.length === 2 && !('0' in a) && a[1] === 1, '[ , expr, ]')
a = [, 1, 2,]
ok(a.length === 3 && !('0' in a) && a[1] === 1 && a[2] === 2,
	'[ , expr, expr, ]')
a = [, 1, , 2,]
ok(a.length === 4 && !('0' in a) && a[1] === 1 && !('2' in a) &&
   a[3]     === 2, '[ , expr, , expr, ]')
a = [, 1, ,, 2,]
ok(a.length === 5 && !('0' in a) && a[1] === 1 && !('2' in a) &&
   !('3' in a)    && a[4] === 2, '[ , expr, ,, expr, ]')
a = [,, 1,]
ok(a.length === 3 && !('0' in a) && !('1' in a) && a[2] === 1,
	'[ ,, expr, ]')
a = [,, 1, 2,]
ok(a.length === 4 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   a[3]     === 2, '[ ,, expr, expr, ]')
a = [,, 1, , 2,]
ok(a.length === 5 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   !('3' in a)    && a[4] === 2, '[ ,, expr, , expr, ]')
a = [,, 1, ,, 2,]
ok(a.length === 6 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   !('3' in a)    && !('4' in a) && a[5] === 2, '[ ,, expr, ,, expr, ]')
a = [1, ,]
ok(a.length === 2 && a[0] === 1 && !('1' in a), '[ expr, , ]')
a = [1, 2, ,]
ok(a.length === 3 && a[0] === 1 && a[1] === 2 && !('2' in a),
	'[ expr, expr, , ]')
a = [1, , 2, ,]
ok(a.length === 4 && a[0] === 1 && !('1' in a) && a[2] === 2 &&
   !('3' in a),	'[ expr, , expr, , ]')
a = [1, ,, 2, ,]
ok(a.length === 5 && a[0] === 1 && !('1' in a) && !('2' in a) &&
   a[3]     === 2 && !('4' in a), '[ expr, ,, expr, , ]')
a = [, 1, ,]
ok(a.length === 3 && !('0' in a) && a[1] === 1 && !('2' in a),
	'[ , expr, , ]')
a = [, 1, 2, ,]
ok(a.length === 4 && !('0' in a) && a[1] === 1 && a[2] === 2 &&
   !('3' in a), '[ , expr, expr, , ]')
a = [, 1, , 2, ,]
ok(a.length === 5 && !('0' in a) && a[1] === 1 && !('2' in a) &&
   a[3]     === 2 && !('4' in a), '[ , expr, , expr, , ]')
a = [, 1, ,, 2, ,]
ok(a.length === 6 && !('0' in a) && a[1] === 1 && !('2' in a) &&
   !('3' in a)    && a[4] === 2  && !('5' in a), '[ , expr, ,, expr, , ]')
a = [,, 1, ,]
ok(a.length === 4 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   !('3' in a), '[ ,, expr, , ]')
a = [,, 1, 2, ,]
ok(a.length === 5 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   a[3]     === 2 && !('4' in a), '[ ,, expr, expr, , ]')
a = [,, 1, , 2, ,]
ok(a.length === 6 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   !('3' in a)    && a[4] === 2  && !('5' in a), '[ ,, expr, , expr, , ]')
a = [,, 1, ,, 2, ,]
ok(a.length === 7 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   !('3' in a)    && !('4' in a) && a[5] === 2  && !('6' in a),
	'[ ,, expr, ,, expr, , ]')
a = [1, ,,]
ok(a.length === 3 && a[0] === 1 && !('1' in a) && !('2' in a),
	'[ expr, ,, ]')
a = [1, 2, ,,]
ok(a.length === 4 && a[0] === 1 && a[1] === 2 && !('2' in a) &&
   !('3' in a), '[ expr, expr, ,, ]')
a = [1, , 2, ,,]
ok(a.length === 5 && a[0] === 1 && !('1' in a) && a[2] === 2 &&
   !('3' in a)    && !('4' in a), '[ expr, , expr, ,, ]')
a = [1, ,, 2, ,,]
ok(a.length === 6 && a[0] === 1  && !('1' in a) && !('2' in a) &&
   a[3]     === 2 && !('4' in a) && !('5' in a), '[ expr, ,, expr, ,, ]')
a = [, 1, ,,]
ok(a.length === 4 && !('0' in a) && a[1] === 1 && !('2' in a) &&
   !('3' in a), '[ , expr, ,, ]')
a = [, 1, 2, ,,]
ok(a.length === 5 && !('0' in a) && a[1] === 1 && a[2] === 2 &&
   !('3' in a)    && !('4' in a), '[ , expr, expr, ,, ]')
a = [, 1, , 2, ,,]
ok(a.length === 6 && !('0' in a) && a[1] === 1 && !('2' in a) &&
   a[3]     === 2 && !('4' in a) && !('5' in a), '[ , expr, , expr, ,, ]')
a = [, 1, ,, 2, ,,]
ok(a.length === 7 && !('0' in a) && a[1] === 1  && !('2' in a) &&
   !('3' in a)    && a[4] === 2  && !('5' in a) && !('6' in a),
	'[ , expr, ,, expr, ,, ]')
a = [,, 1, ,,]
ok(a.length === 5 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   !('3' in a)    && !('4' in a), '[ ,, expr, ,, ]')
a = [,, 1, 2, ,,]
ok(a.length === 6 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   a[3]     === 2 && !('4' in a) && !('5' in a), '[ ,, expr, expr, ,, ]')
a = [,, 1, , 2, ,,]
ok(a.length === 7 && !('0' in a) && !('1' in a) && a[2] === 1 &&
   !('3' in a)    && a[4] === 2  && !('5' in a) && !('6' in a),
	'[ ,, expr, , expr, ,, ]')
a = [,, 1, ,, 2, ,,]
ok(a.length === 8 && !('0' in a) && !('1' in a) && a[2] === 1  &&
   !('3' in a)    && !('4' in a) && a[5] === 2  && !('6' in a) &&
   !('7' in a), '[ ,, expr, ,, expr, ,, ]')

var error = false
try {
 a = [i_hope_this_variable_does_not_exist]
}
catch(e) { error = e }
ok(error instanceof ReferenceError, 'array literals resolve lvalues');


// ===================================================
// 11.1.3 Object literals
// ===================================================

/* Tests 61-73 */

function keys(obj) {
	var k = []
	for(k[k.length] in obj);
	return k
}

o = {}
ok(keys(o) == '',                                  '{ }')
o = { Makarios: 'anēr' }
ok(keys(o) == 'Makarios' && o.Makarios === 'anēr', '{ identifier: expr }')
o = { hos:      'ouk', eporeuthē: 'en' }
ok(keys(o) == 'hos,eporeuthē' && o.hos === 'ouk' && o.eporeuthē === 'en',
   '{ identifier: expr, identifier: expr }')
o = { boulē: 'asebōn,', 'kai': 'en' }
ok(keys(o) == 'boulē,kai' && o.boulē === 'asebōn,' && o.kai === 'en', 
   '{ identifier: expr, string: expr }')
o = { hodōi: 'hamartolōn', 1: 'ouk' }
ok(keys(o) == 'hodōi,1' && o.hodōi === 'hamartolōn' && o[1] === 'ouk',
   '{ identifier: expr, number: expr }')
o = { 'estē,': 'kai' }
ok(keys(o) == 'estē,'     && o['estē,'] === 'kai', '{ string: expr }')
o = { 'epi':  'kathedrāi', limōn: 'ouk' }
ok(keys(o) == 'epi,limōn' && o.epi === 'kathedrāi' && o.limōn === 'ouk',
   '{ string: expr, identifier: expr }')
o = { 'ekathisen.': 'All’', 'ē': 'en' }
ok(keys(o) == 'ekathisen.,ē' && o['ekathisen.'] === 'All’' && o.ē === 'en',
   '{ string: expr, string: expr }')
o = { 'tōi': 'nomōi', 2: 'Kyriou' }
ok(keys(o) == 'tōi,2' && o.tōi === 'nomōi' && o[2] === 'Kyriou',
   '{ string: expr, number: expr }')
o = { 3: 'to' }
ok(keys(o) == '3'       && o[3] === 'to', '{ number: expr }')
o = { 4: 'thelēma', autou: 'kai' }
ok(keys(o) == '4,autou' && o[4] === 'thelēma' && o.autou === 'kai',
   '{ number: expr, identifier: expr }')
o = { 5: 'en', 'to': 'nomōi' }
ok(keys(o) == '5,to' && o[5] === 'en' && o.to === 'nomōi',
   '{ number: expr, string: expr }')
o = { 6: 'autou', 7: 'meletēsei' }
ok(keys(o) == '6,7' && o[6] === 'autou' && o[7] === 'meletēsei',
   '{ number: expr, number: expr }')


// ===================================================
// 11.1.3 Grouping parentheses
// ===================================================

/* Test 74 */

ok((3)===3, 'grouping parentheses')

--end--
