#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 111;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );


# JS tests
defined $j->eval( <<'--end--' ) or die;

// ===================================================
// 11.4.1 delete
// ===================================================

/* Tests 4-15 */

s = String;

var x //undeletable
eval('var y,z') //deletable
ok( delete(x,y)   &&  'x' in this && 'y' in this, 'delete(a,b)')
ok( delete(x=3)   &&  'x' in this,                'delete(a=b)')
ok( delete(1?y:x) &&  'y' in this,                'delete(a?b:c)')
ok( delete(x||y)  &&  'x' in this && 'y' in this, 'delete(a||b)')
ok( delete(x&&y)  &&  'x' in this && 'y' in this, 'delete(a&&b)')
ok( delete "y"    &&  'y' in this,               'delete "a"')
ok( delete  y     &&!('y' in this),            'delete a')
ok( delete( z )   &&!('z' in this),          'delete(a)')
ok(!delete  x      &&  'x' in this,       'delete a when a is undeletable')
ok( delete  w        &&!('w' in this),  'delete a when a does not exist')
ok( delete this.String &&!('String' in this), 'delete a.b')
// Hey, wait a minute! I still need that! Better put it back:
String = s
ok( delete []["\ud800"], 'delete []["\\ud800"]')

// ===================================================
// 11.4.2 void
// ===================================================

/* Tests 16-17 */

ok(typeof void delete undefined == 'undefined', 'void expr')
error = 0
try { void oentuahn }
catch(me) { me instanceof ReferenceError && (error = 1) }
ok(error, '"void identifier" when var does not exist')


// ===================================================
// 11.4.3 typeof
// ===================================================

/* Tests 18-33 */

ok(          typeof undefined === 'undefined', 'typeof undefined (lvalue)')
ok((x = null, typeof x        === 'object'),   'typeof null (lvalue)')
ok((x = true, typeof x        === 'boolean'),  'typeof boolean (lvalue)')
ok((x = 0,    typeof x        === 'number'),   'typeof number (lvalue)')
ok((x = '',   typeof x        === 'string'),   'typeof string (lvalue)')
ok((x = {},   typeof x        === 'object'),   'typeof object (lvalue)')
ok(           typeof eval     === 'function',  'typeof function (lvalue)')
ok(           typeof easun     === 'undefined', 'typeof nonexistent_var')
ok(           typeof '3'.toStoo === 'undefined', 'typeof nonexistent.prop')
ok(           typeof void 0     === 'undefined', 'typeof undefined')
ok(           typeof null       === 'object',    'typeof null')
ok(           typeof true       === 'boolean',   'typeof boolean')
ok(           typeof 3           === 'number',    'typeof number')
ok(           typeof '3'           === 'string',   'typeof string')
ok(           typeof new new Function === 'object',  'typeof object')
ok(           typeof new Function       === 'function', 'typeof function')


// ===================================================
// 11.4.4 ++
// ===================================================

/* Tests 34-41 */

ok((x = void 0, isNaN(++x)  && isNaN(x)),  '++undefined')
ok((x = null,   ++x === 1   && x === 1),   '++null')
ok((x = true,   ++x === 2   && x === 2),   '++true')
ok((x = false,  ++x === 1   && x === 1),   '++false')
ok((x = 'a',    isNaN(++x)  && isNaN(x)),  '++"a"')
ok((x = '3',    ++x === 4   && x === 4),   '++"3"')
ok((x = 4.2,    ++x === 5.2 && x === 5.2), '++4.2')
ok((x = {},     isNaN(++x)  && isNaN(x)),  '++{}')


// ===================================================
// 11.4.5 --
// ===================================================

/* Tests 42-9 */

ok((x = void 0, isNaN(--x)         && isNaN(x)),         '--undefined')
ok((x = null,         --x === -1   &&       x === -1),   '--null')
ok((x = true,         --x ===  0   &&       x ===  0),   '--true')
ok((x = false,        --x === -1   &&       x === -1),   '--false')
ok((x = 'a',    isNaN(--x)         && isNaN(x)),         '--"a"')
ok((x = '3',          --x ===  2   &&       x ===  2),   '--"3"')
ok((x = 4.2,          --x ===  3.2 &&       x ===  3.2), '--4.2')
ok((x = {},     isNaN(--x)         && isNaN(x)),         '--{}')


// ===================================================
// 11.4.6 +
// ===================================================

/* Tests 50-7 */

ok(isNaN(+void 0),        '+undefined')
ok(      +null   === 0,   '+null')
ok(      +true   === 1,   '+true')
ok(      +false  === 0,   '+false')
ok(isNaN(+'a'),           '+"a"')
ok(      +'3.00' === 3,   '+"3.00"')
ok(      +4.2    === 4.2, '+4.2')
ok(isNaN(+{}),            '+{}')


// ===================================================
// 11.4.7 -
// ===================================================

/* Tests 58-66 */

ok(isNaN(-void 0),         '-undefined')
ok(      -null   ===  0,   '-null')
ok(      -true   === -1,   '-true')
ok(      -false  ===  0,   '-false')
ok(isNaN(-'a'),            '-"a"')
ok(      -"-5"   ===  5,   '-"-5"')
ok(      -4.2    === -4.2, '-4.2')
ok(isNaN(-{}),             '-{}')
ok(      - -5    ===  5,   '- -5')


// ===================================================
// 11.4.8 ~
// ===================================================

/* Tests 67-101 */

ok(~ undefined      === -1         , "~undefined"      )
ok(~ null           === -1         , "~null"           )
ok(~ true           === -2         , "~true"           )
ok(~ false          === -1         , "~false"          )
ok(~'a'             === -1         , "~'a'"            )
ok(~'3'             === -4         , "~'3'"            )
ok(~ {}             === -1         , "~{}"             )
ok(~ NaN            === -1         , "~NaN"            )
ok(~ 0              === -1         , "~0"              )
ok(~-0              === -1         , "~-0"             )
ok(~ Infinity       === -1         , "~Infinity"       )
ok(~-Infinity       === -1         , "~-Infinity"      )
ok(~ 1              === -2         , "~1"              )
ok(~ 32.5           === -33        , "~32.5"           )
ok(~ 2147483648     ===  2147483647, "~2147483648"     )
ok(~ 3000000000     ===  1294967295, "~3000000000"     )
ok(~ 4000000000.23  ===  294967295 , "~4000000000.23"  )
ok(~ 5000000000     === -705032705 , "~5000000000"     )
ok(~ 4294967296     === -1         , "~4294967296"     )
ok(~ 4294967298.479 === -3         , "~4294967298.479" )
ok(~ 6442450942     === -2147483647, "~6442450942"     )
ok(~ 6442450943.674 === -2147483648, "~6442450943.674" )
ok(~ 6442450944     ===  2147483647, "~6442450944"     )
ok(~ 6442450945     ===  2147483646, "~6442450945"     )
ok(~ 6442450946.74  ===  2147483645, "~6442450946.74"  )
ok(~-1              ===  0         , "~-1"             )
ok(~-32.5           ===  31        , "~-32.5"          )
ok(~-3000000000     === -1294967297, "~-3000000000"    )
ok(~-4000000000.23  === -294967297 , "~-4000000000.23" )
ok(~-5000000000     ===  705032703 , "~-5000000000"    )
ok(~-4294967298.479 ===  1         , "~-4294967298.479")
ok(~-6442450942     ===  2147483645, "~-6442450942"    )
ok(~-6442450943.674 ===  2147483646, "~-6442450943.674")
ok(~-6442450945     === -2147483648, "~-6442450945"    )
ok(~-6442450946.74  === -2147483647, "~-6442450946.74" )


// ===================================================
// 11.4.9 !
// ===================================================

/* Tests 102-11 */

ok(!undefined === true , "!undefined")
ok(!null      === true , "!null"     )
ok(!true      === false, "!true"     )
ok(!false     === true , "!false"    )
ok(!''        === true , "!''"       )
ok(!"false"   === false, "!\"false\"")
ok(!0         === true , '!0'        )
ok(!1         === false, '!1'        )
ok(!NaN       === true , "!NaN"      )
ok(!{}        === false, "!{}"       )

--end--
