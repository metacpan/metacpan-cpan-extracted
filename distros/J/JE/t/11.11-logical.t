#!perl -T
do './t/jstest.pl' or die __DATA__

plan('tests', 102)

// Binary Logical Operators

o = {}
n = new Number(34.2)

// ===================================================
// &&
// ===================================================

/* Tests 1-51: Type conversion */

// some of these are probably useless, but it takes too long to sift
// through them

ok((void 0 && void 0) === void 0, "undefined && undefined")
ok((void 0 && null) === void 0, "undefined && null")
ok((void 0 && true) === void 0, "undefined && boolean")
ok((void 0 && "3") === void 0, "undefined && string")
ok((void 0 && 73) === void 0, "undefined && number")
ok((void 0 && {}) === void 0, "undefined && object")
ok((void 0 && new Number(34.2)) === void 0, "undefined && number object")
ok((null && void 0) === null, "null && undefined")
ok((null && null) === null, "null && null")
ok((null && true) === null, "null && boolean")
ok((null && "3") === null, "null && string")
ok((null && 73) === null, "null && number")
ok((null && {}) === null, "null && object")
ok((null && new Number(34.2)) === null, "null && number object")
ok((true && void 0) === void 0, "boolean && undefined")
ok((true && null) === null, "boolean && null")
ok((true && true) === true, "boolean && boolean")
ok((true && "3") === "3", "boolean && string")
ok((true && 73) === 73, "boolean && number")
ok((true && o) === o, "boolean && object")
ok((true && n) === n, "boolean && number object")
ok(("3" && void 0) === void 0, "string && undefined")
ok(("3" && null) === null, "string && null")
ok(("3" && true) === true, "string && boolean")
ok(("3" && "3") === "3", "string && string")
ok(("3" && 73) === 73, "string && number")
ok(("3" && o) === o, "string && object")
ok(("3" && n) === n, "string && number object")
ok((73 && void 0) === void 0, "number && undefined")
ok((73 && null) === null, "number && null")
ok((73 && true) === true, "number && boolean")
ok((73 && "3") === "3", "number && string")
ok((73 && 73) === 73, "number && number")
ok((73 && o) === o, "number && object")
ok((73 && n) === n, "number && number object")
ok(({} && void 0) === void 0, "object && undefined")
ok(({} && null) === null, "object && null")
ok(({} && true) === true, "object && boolean")
ok(({} && "3") === "3", "object && string")
ok(({} && 73) === 73, "object && number")
ok(({} && o) === o, "object && object")
ok(({} && n) === n, "object && number object")
ok((new Number(34.2) && void 0) === void 0, "number object && undefined")
ok((new Number(34.2) && null) === null, "number object && null")
ok((new Number(34.2) && true) === true, "number object && boolean")
ok((new Number(34.2) && "3") === '3', "number object && string")
ok((new Number(34.2) && 73) === 73, "number object && number")
ok((new Number(34.2) && o) === o, "number object && object")
ok((new Number(34.2) && n) === n, "number object && number object")

/* control flow and short-circuiting */

run = false
function test(x) { run = true; return 1 }
ok((true && test()) === 1 && run === true,
	'"true && somewhat" does not short-circuit')
run=false
ok((0 && test()) === 0 && run === false,
	'"false && somewhat" shorts the circuit')


// ===================================================
// ||
// ===================================================

/* Tests 52-102 */

ok((void 0 || void 0) === void 0, "undefined || undefined")
ok((void 0 || null) === null, "undefined || null")
ok((void 0 || true) === true, "undefined || boolean")
ok((void 0 || "3") === '3', "undefined || string")
ok((void 0 || 73) === 73, "undefined || number")
ok((void 0 || o) === o, "undefined || object")
ok((void 0 || n) === n, "undefined || number object")
ok((null || void 0) === void 0, "null || undefined")
ok((null || null) === null, "null || null")
ok((null || true) === true, "null || boolean")
ok((null || "3") === '3', "null || string")
ok((null || 73) === 73, "null || number")
ok((null || o) === o, "null || object")
ok((null || n) === n, "null || number object")
ok((true || void 0) === true, "boolean || undefined")
ok((true || null) === true, "boolean || null")
ok((true || true) === true, "boolean || boolean")
ok((true || "3") === true, "boolean || string")
ok((true || 73) === true, "boolean || number")
ok((true || o) === true, "boolean || object")
ok((true || n) === true, "boolean || number object")
ok(("3" || void 0) === '3', "string || undefined")
ok(("3" || null) === '3', "string || null")
ok(("3" || true) === '3', "string || boolean")
ok(("3" || "3") === "3", "string || string")
ok(("3" || 73) === '3', "string || number")
ok(("3" || o) === '3', "string || object")
ok(("3" || n) === '3', "string || number object")
ok((73 || void 0) === 73, "number || undefined")
ok((73 || null) === 73, "number || null")
ok((73 || true) === 73, "number || boolean")
ok((73 || "3") === 73, "number || string")
ok((73 || 73) === 73, "number || number")
ok((73 || o) === 73, "number || object")
ok((73 || n) === 73, "number || number object")
ok((o || void 0) === o, "object || undefined")
ok((o || null) === o, "object || null")
ok((o || true) === o, "object || boolean")
ok((o || "3") === o, "object || string")
ok((o || 73) === o, "object || number")
ok((o || o) === o, "object || object")
ok((o || n) === o, "object || number object")
ok((n|| void 0) === n, "number object || undefined")
ok((n|| null) === n, "number object || null")
ok((n|| true) === n, "number object || boolean")
ok((n|| "3") === n, "number object || string")
ok((n|| 73) === n, "number object || number")
ok((n|| {}) === n, "number object || object")
ok((n|| new Number(2343894)) === n, "number object || number object")

run = false
ok((false || test()) === 1 && run === true,
	'"false && somewhat" does not short-circuit')
run=false
ok((true || test()) === true && run === false,
	'"true || somewhat" shorts the circuit')

