#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 218;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-4: Bind the ok, is and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( is  => \&is   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );


# JS tests
defined $j->eval( <<'--end--' ) or die;

// ===================================================
// 11.9.1 ==
// ===================================================

/* Tests 5-55 */

ok(void 0 == void 0 === true, "undefined == undefined")
ok(void 0 == null === true, "undefined == null")
ok(void 0 == true === false, "undefined == boolean")
ok(void 0 == "O" === false, "undefined == string")
ok(void 0 == 73 === false, "undefined == number")
ok(void 0 == {} === false, "undefined == object")
ok(void 0 == new Number(34.2) === false, "undefined == number object")
ok(null == void 0 === true, "null == undefined")
ok(null == null === true, "null == null")
ok(null == true === false, "null == boolean")
ok(null == "0" === false, "null == string")
ok(null == 0 === false, "null == number")
ok(null == {} === false, "null == object")
ok(null == new Number(0) === false, "null == number object")
ok(true == void 0 === false, "boolean == undefined")
ok(true == null === false, "boolean == null")
ok(true == true === true, "boolean == boolean")
ok(true == "1" === true, "boolean == string")
ok(true == 1 === true, "boolean == number")
ok(true == {} === false, "boolean == object")
ok(true == new Number(1) === true, "boolean == number object")
ok("3" == void 0 === false, "string == undefined")
ok("null" == null === false, "string == null")
ok("1" == true === true, "string == boolean")
ok("3" == "3.0" === false, "string == string")
ok("3.0" == 3 === true, "string == number")
ok("[object Object]" == {} === true, "string == object")
ok("03" == new Number(3) === true, "string == number object")
ok(NaN == void 0 === false, "number == undefined")
ok(0 == null === false, "number == null")
ok(1 == true === true, "number == boolean")
ok(23 == "023" === true, "number == string")
ok(73 == 73 === true, "number == number")
ok(73 == {} === false, "number == object")
ok(73 == new Number(34.2) === false, "number == number object")
ok({} == void 0 === false, "object == undefined")
ok({} == null === false, "object == null")
ok({} == true === false, "object == boolean")
ok({} == "[object Object]" === true, "object == string")
ok({} == 73 === false, "object == number")
ok({} == {} === false, "object == different object")
o = {}
ok(o == o === true, 'object == same object')
ok({} == new Number(34.2) === false, "object == number object")
ok(new Number(34.2) == void 0 === false, "number object == undefined")
ok(new Number(34.2) == null === false, "number object == null")
ok(new Number(34.2) == true === false, "number object == boolean")
ok(new Number(24.2) == "3" === false, "number object == string")
ok(new Number(34.2) == 73 === false, "number object == number")
ok(new Number(34.2) == {} === false, "number object == object")
ok(new Number(34.2) == new Number(34.2) === false, "number object == number object")
ok(NaN == NaN === false, 'nan == nan')

/* Test 56 */
expr = 1
is(expr == (expr = 2), false, 'lvalue == expr modifying the lvalue');

// ===================================================
// 11.9.2 !=
// ===================================================

/* Tests 57-107 */

ok(void 0 != void 0 === false, "undefined != undefined")
ok(void 0 != null === false, "undefined != null")
ok(void 0 != true === true, "undefined != boolean")
ok(void 0 != "O" === true, "undefined != string")
ok(void 0 != 73 === true, "undefined != number")
ok(void 0 != {} === true, "undefined != object")
ok(void 0 != new Number(34.2) === true, "undefined != number object")
ok(null != void 0 === false, "null != undefined")
ok(null != null === false, "null != null")
ok(null != true === true, "null != boolean")
ok(null != "0" === true, "null != string")
ok(null != 0 === true, "null != number")
ok(null != {} === true, "null != object")
ok(null != new Number(0) === true, "null != number object")
ok(true != void 0 === true, "boolean != undefined")
ok(true != null === true, "boolean != null")
ok(true != true === false, "boolean != boolean")
ok(true != "1" === false, "boolean != string")
ok(true != 1 === false, "boolean != number")
ok(true != {} === true, "boolean != object")
ok(true != new Number(1) === false, "boolean != number object")
ok("3" != void 0 === true, "string != undefined")
ok("0" != null === true, "string != null")
ok("1" != true === false, "string != boolean")
ok("3" != "3.0" === true, "string != string")
ok("3.0" != 3 === false, "string != number")
ok("[object Object]" != {} === false, "string != object")
ok("03" != new Number(3) === false, "string != number object")
ok(NaN != void 0 === true, "number != undefined")
ok(0 != null === true, "number != null")
ok(1 != true === false, "number != boolean")
ok(23 != "023" === false, "number != string")
ok(73 != 73 === false, "number != number")
ok(73 != {} === true, "number != object")
ok(73 != new Number(34.2) === true, "number != number object")
ok({} != void 0 === true, "object != undefined")
ok({} != null === true, "object != null")
ok({} != true === true, "object != boolean")
ok({} != "[object Object]" === false, "object != string")
ok({} != 73 === true, "object != number")
ok({} != {} === true, "object != different object")
o = {}
ok(o != o === false, 'object != same object')
ok({} != new Number(34.2) === true, "object != number object")
ok(new Number(34.2) != void 0 === true, "number object != undefined")
ok(new Number(34.2) != null === true, "number object != null")
ok(new Number(34.2) != true === true, "number object != boolean")
ok(new Number(24.2) != "3" === true, "number object != string")
ok(new Number(34.2) != 73 === true, "number object != number")
ok(new Number(34.2) != {} === true, "number object != object")
ok(new Number(34.2) != new Number(34.2) === true, "number object != number object")
ok(NaN != NaN === true, 'nan != nan')

/* Test 108 */
expr = 1
is(expr != (expr = 2), true, 'lvalue != expr modifying the lvalue');


// ===================================================
// 11.9.4 ===
// ===================================================

/* Tests 109-62 */

is(void 0 === void 0,  true, "undefined === undefined")
is(void 0 === null,  false, "undefined === null")
is(void 0 === true,  false, "undefined === boolean")
is(void 0 === "O",  false, "undefined === string")
is(void 0 === 73,  false, "undefined === number")
is(void 0 === {},  false, "undefined === object")
is(void 0 === new Number(34.2),  false, "undefined === number object")
is(null === void 0,  false, "null === undefined")
is(null === null,  true, "null === null")
is(null === true,  false, "null === boolean")
is(null === "3",  false, "null === string")
is(null === 73,  false, "null === number")
is(null === {},  false, "null === object")
is(null === new Number(34.2),  false, "null === number object")
is(true === void 0,  false, "boolean === undefined")
is(true === null,  false, "boolean === null")
is(true === true,  true, "true === true")
is(true === false,  false, "true === false")
is(true === "3",  false, "boolean === string")
is(true === 73,  false, "boolean === number")
is(true === {},  false, "boolean === object")
is(true === new Number(34.2),  false, "boolean === number object")
is("3" === void 0,  false, "string === undefined")
is("3" === null,  false, "string === null")
is("3" === true,  false, "string === boolean")
is("3" === "3",  true, "string === same string")
is("3" === "another stirng",  false, "string === different string")
is("3" === 23,  false, "string === number")
is("3" === {},  false, "string === object")
is("3" === new Number(24.2),  false, "string === number object")
is(73 === void 0,  false, "number === undefined")
is(73 === null,  false, "number === null")
is(73 === true,  false, "number === boolean")
is(23 === "3",  false, "number === string")
is(73 === 73,  true, "number === same number")
is(73 === 74,  false, "number === another number")
is(NaN === NaN, false, 'nan === nan')
is(73 === {},  false, "number === object")
is(73 === new Number(34.2),  false, "number === number object")
is({} === void 0,  false, "object === undefined")
is({} === null,  false, "object === null")
is({} === true,  false, "object === boolean")
is({} === "[p",  false, "object === string")
is({} === 73,  false, "object === number")
is({} === {},  false, "object === another object")
is(o === o,  true, "object === same object")
is({} === new Number(34.2),  false, "object === number object")
is(new Number(34.2) === void 0,  false, "number object === undefined")
is(new Number(34.2) === null,  false, "number object === null")
is(new Number(34.2) === true,  false, "number object === boolean")
is(new Number(24.2) === "3",  false, "number object === string")
is(new Number(34.2) === 73,  false, "number object === number")
is(new Number(34.2) === {},  false, "number object === object")
is(new Number(34.2) === new Number(34.2),  false, "number object === number object")

/* Test 163 */
expr = 1
is(expr === (expr = 2), false, 'lvalue === expr modifying the lvalue');


// ===================================================
// 11.9.5 !==
// ===================================================

/* Tests 164-217 */

is(void 0 !== void 0, false, "undefined !== undefined")
is(void 0 !== null, true, "undefined !== null")
is(void 0 !== true, true, "undefined !== boolean")
is(void 0 !== "O", true, "undefined !== string")
is(void 0 !== 73, true, "undefined !== number")
is(void 0 !== {}, true, "undefined !== object")
is(void 0 !== new Number(34.2), true, "undefined !== number object")
is(null !== void 0, true, "null !== undefined")
is(null !== null, false, "null !== null")
is(null !== true, true, "null !== boolean")
is(null !== "3", true, "null !== string")
is(null !== 73, true, "null !== number")
is(null !== {}, true, "null !== object")
is(null !== new Number(34.2), true, "null !== number object")
is(true !== void 0, true, "boolean !== undefined")
is(true !== null, true, "boolean !== null")
is(true !== true, false, "true !== true")
is(true !== false, true, "true !== false")
is(true !== "3", true, "boolean !== string")
is(true !== 73, true, "boolean !== number")
is(true !== {}, true, "boolean !== object")
is(true !== new Number(34.2), true, "boolean !== number object")
is("3" !== void 0, true, "string !== undefined")
is("3" !== null, true, "string !== null")
is("3" !== true, true, "string !== boolean")
is("3" !== "3", false, "string !== same string")
is("3" !== "another stirng", true, "string !== different string")
is("3" !== 23, true, "string !== number")
is("3" !== {}, true, "string !== object")
is("3" !== new Number(24.2), true, "string !== number object")
is(73 !== void 0, true, "number !== undefined")
is(73 !== null, true, "number !== null")
is(73 !== true, true, "number !== boolean")
is(23 !== "3", true, "number !== string")
is(73 !== 73, false, "number !== same number")
is(73 !== 74, true, "number !== another number")
is(NaN !== NaN, true, 'nan !== nan')
is(73 !== {}, true, "number !== object")
is(73 !== new Number(34.2), true, "number !== number object")
is({} !== void 0, true, "object !== undefined")
is({} !== null, true, "object !== null")
is({} !== true, true, "object !== boolean")
is({} !== "[p", true, "object !== string")
is({} !== 73, true, "object !== number")
is({} !== {}, true, "object !== another object")
is(o !== o, false, "object !== same object")
is({} !== new Number(34.2), true, "object !== number object")
is(new Number(34.2) !== void 0, true, "number object !== undefined")
is(new Number(34.2) !== null, true, "number object !== null")
is(new Number(34.2) !== true, true, "number object !== boolean")
is(new Number(24.2) !== "3", true, "number object !== string")
is(new Number(34.2) !== 73, true, "number object !== number")
is(new Number(34.2) !== {}, true, "number object !== object")
is(new Number(34.2) !== new Number(34.2), true, "number object !== number object")

/* Test 218 */
expr = 1
is(expr !== (expr = 2), true, 'lvalue !== expr modifying the lvalue');


--end--
