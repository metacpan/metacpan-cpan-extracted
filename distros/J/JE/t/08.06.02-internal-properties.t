#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 58;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );


# Run JS tests

defined $j->eval( <<'--end--' ) or die;

// ---------------------------------------------------
/* Tests 4-6: Verify that accessing unimplemented internal properties caus-
             es TypeErrors */

var is_TypeError;

try { new 'Object'() }
catch (e) {
	e instanceof TypeError && (is_TypeError = true)
}
ok(is_TypeError, '"string".[[Construct]] throws TypeError')
//diag("Did I fail this test?: " + is_TypeError);

is_TypeError = false
try { 'function'() }
catch (e) {
	e instanceof TypeError && (is_TypeError = true)
}
ok(is_TypeError, '"string".[[Call]] throws TypeError')

is_TypeError = false
try { function(){} instanceof 'Function' }
catch (e) {
	e instanceof TypeError && (is_TypeError = true)
}
ok(is_TypeError, 'x instanceof "string" throws TypeError')

// ---------------------------------------------------
/* Tests 7-11: [[Get]] */

ok(String.length !== undefined, '[[Get]] when object has its own property')

ok((f = {}.toString) !== undefined && f === Object.prototype.toString,
    '[[Get]] when object inherits from its prototype')

ok((f = {}.oString) === undefined,
    '[[Get]] when neither the object nor its prototype has the property')

ok( Object.prototype.et === undefined,
    '[[Get]] when object has neither the named property nor a prototype')

Object.prototype.gizmo = 'ansthstyyyyyyyyyyyyyyyy';
ok( new String().gizmo === 'ansthstyyyyyyyyyyyyyyyy',
    '[[Get]] when object inherits from its prototype\'s prototype')

// ---------------------------------------------------
/* Tests 12-17: [[Put]] */

Object.prototype = new Function;
ok(typeof Object.prototype == 'object',
    '[[Put]] when property is readonly')

Infinity = 7 // :-)
var found_inf
for(var p in this) if (p == 'Infinity') { found_inf = true; break }
ok(Infinity === 7 &&
   !found_inf /* verifies that the dontenum attr is unchanged */,
    '[[Put]] when property exists and is not readonly')

function Constructor(){}
Constructor.prototype = Object // This is how I get read-only properties
thing = new Constructor       // on to the prototype chain.
thing.prototype = 7
ok(thing.prototype !== 7,
    '[[Put]] can\'t obscure read-only properties of prototypes')

Object.prototype.fibungle = 'antidisestablishmentarianism';
(thing = {})   .fibungle = 'floccipaucinihilopilification'
ok({}.fibungle == 'antidisestablishmentarianism' &&
   thing.fibungle == 'floccipaucinihilopilification',
   '[[Put]] creates a new property and leaves the prototype\'s one alone');

(thing = {}).codswallop = 'pneumonoultramicroscopicsilicovolcanoconiosis'
ok(!('codswallop' in Object.prototype) &&
   thing.codswallop === 'pneumonoultramicroscopicsilicovolcanoconiosis',
    '[[Put]] creates a new property and leaves the prototype alone')

Object.prototype["Bob's my uncle!"] = 'something'
ok(Object.prototype["Bob's my uncle!"] === 'something',
    '[[Put]], when object has no prototype')

// ---------------------------------------------------
/* Tests 18-21: [[HasProperty]] */

ok('String' in this,
    '[[HasProperty]] when the object has an uninherited property')

ok('toString' in {},
    '[[HasProperty]] when the object has an inherited property')

ok(!('$@C@YH<ICR%H"DR#' in {}),
    '[[HasProperty]] when neither the obj nor its proto has the property')

ok(!('$@C@YH<ICR%H"DR#' in Object.prototype),
    '[[HasProperty]] when the obj has neither the prop nor a prototype')

// ---------------------------------------------------
/* Tests 22-24: [[Delete]] */

ok(!delete String.prototype,
    '[[Delete]] when the property exists and is undeletable')

ok(delete Function, // Who wants this anyway? :-)
    '[[Delete]] when the property exists and is deletable')

ok(delete everything_else,
    '[[Delete]] when the property is non-existent')

// ---------------------------------------------------
/* Tests 25-58: [[DefaultValue]] */

/* possible outcomes
This chart is based on the algorithms described in 8.6.2.6
(func means "Is the aforementioned object a function?"
(prim res means "Have we a primitive result after calling the function?")

Note that, if the first method that is tried is an object but is not a
function, a TypeError is thrown and the other method is ignored.

hint string
toString  func?  prim res?  valueOf  func?  prim res?  outcome
is obj?                     is obj?
yes       yes    yes                                   toString()
yes       yes    no         yes       yes   yes        valueOf()
yes       yes    no         yes       yes   no         TypeError
yes       yes    no         yes       no               TypeError
yes       yes    no         no                         TypeError
yes       no                                           TypeError
no                          yes       yes   yes        valueOf()
no                          yes       yes   no         TypeError
no                          yes       no               TypeError
no                          no                         TypeError

hint number
valueOf  func?  prim res?  toString  func?  prim res?  outcome
is obj?                     is obj?
yes      yes    yes                                    valueOf()
yes      yes    no         yes        yes   yes        toString()
yes      yes    no         yes        yes   no         TypeError
yes      yes    no         yes        no               TypeError
yes      yes    no         no                          TypeError
yes      no                                            TypeError
no                         yes        yes   yes        toString()
no                         yes        yes   no         TypeError
no                         yes        no               TypeError
no                         no                          TypeError
*/

delete Object.prototype.toString; // We don't want these messing up
delete Object.prototype.valueOf; // our test.

function gimme_5() { return 5 }
function gimme_7 () { return 7 }
function gimme_obj() { return {} }

// When the hint is 'string':

test_obj = { toString: gimme_7, valueOf: gimme_5 };
ok(String(test_obj) === '7',
	'[[DefaultValue]](string) when toString() returns a primitive')

test_obj = { toString: gimme_obj, valueOf: gimme_5 }
ok(String(test_obj) === '5',
	'[[DefaultValue]](string) when toString returns a object and '+
	'valueOf returns a primitive')

test_obj = { toString: gimme_obj, valueOf: gimme_obj }
is_TypeError = false
try { String(test_obj) }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](string) when toString and valueOf return objects')

test_obj = { toString: gimme_obj, valueOf: {} }
is_TypeError = false
try { String(test_obj) }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](string) when toString returns an obj and typeof '+
    'valueOf == "object"')

test_obj = { toString: gimme_obj }
is_TypeError = false
try { String(test_obj) }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](string) when toString returns an obj and there is '+
    'no valueOf')

test_obj = { toString: {} }
is_TypeError = false
try { String(test_obj) }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](string) when typeof toString == "object"')

test_obj = { valueOf: gimme_5 }
ok(String(test_obj) === '5',
    '[[DefaultValue]](string) when there is no toString and valueOf' +
    ' returns a primitive')

test_obj = { valueOf: gimme_obj }
is_TypeError = false
try { String(test_obj) }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](string) when there is no toString and valueOf' +
    ' returns an object')

test_obj = { valueOf: {} }
is_TypeError = false
try { String(test_obj) }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](string) when there is no toString and valueOf' +
    ' is a non-function object')

test_obj = {  }
is_TypeError = false
try { String(test_obj) }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](string) when neither toString nor valueOf exists')

// When the hint is 'number':

test_obj = { valueOf: gimme_7, toString: gimme_5 };
ok(+test_obj === 7,
	'[[DefaultValue]](number) when valueOf() returns a primitive')

test_obj = { valueOf: gimme_obj, toString: gimme_5 }
ok(+test_obj === 5,
	'[[DefaultValue]](number) when valueOf returns a object and '+
	'toString returns a primitive')

test_obj = { valueOf: gimme_obj, toString: gimme_obj }
is_TypeError = false
try { +test_obj }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](number) when valueOf and toString return objects')

test_obj = { valueOf: gimme_obj, toString: {} }
is_TypeError = false
try { +test_obj }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](number) when valueOf returns an obj and typeof '+
    'toString == "object"')

test_obj = { valueOf: gimme_obj }
is_TypeError = false
try { +test_obj }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](number) when valueOf returns an obj and there is '+
    'no toString')

test_obj = { valueOf: {} }
is_TypeError = false
try { +test_obj }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](number) when typeof valueOf == "object"')

test_obj = { toString: gimme_5 }
ok(+test_obj === 5,
    '[[DefaultValue]](number) when there is no valueOf and toString' +
    ' returns a primitive')

test_obj = { toString: gimme_obj }
is_TypeError = false
try { +test_obj }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](number) when there is no valueOf and toString' +
    ' returns an object')

test_obj = { toString: {} }
is_TypeError = false
try { +test_obj }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](number) when there is no valueOf and toString' +
    ' is a non-function object')

test_obj = {  }
is_TypeError = false
try { +test_obj }
catch(e) { e instanceof TypeError && ++is_TypeError }
ok(is_TypeError,
    '[[DefaultValue]](number) when neither valueOf nor toString exists')

// When we provide no hint:

Function = Object.constructor; // we got rid of this earlier
constructors = ('Object,Function,Array,String,Boolean,Number,Date,' +
                'RegExp,Error,RangeError,ReferenceError,SyntaxError,' +
                'TypeError,URIError').split(',')

for(var i=0;i<constructors.length;++i)
	this[constructors[i]].prototype.toString = gimme_5,
	this[constructors[i]].prototype.valueOf  = gimme_7,
	// The == provides no hint.
	ok(new this[constructors[i]]() ==
		(constructors[i] == 'Date' ? 5 : 7),
		constructors[i] + ' primitivisation without a hint')


--end--
