#!perl -T
do './t/jstest.pl' or die __DATA__

plan('tests', 11)

// ===================================================
// ?:
// ===================================================

/* Tests 1-8: Type conversion and basic logic */

ok((void 0 ? 2 : 3) === 3, 'undefined ? ... : ...')
ok((null   ? 2 : 3) === 3, 'null ? ... : ...')
ok((true   ? 2 : 3) === 2, 'true ? ... : ...')
ok((false  ? 2 : 3) === 3, 'false ? ... : ...')
ok(('3'    ? 2 : 3) === 2,'string ? ... : ...')
ok((''     ? 2 : 3) === 3,'null string ? ... : ...')
ok((32     ? 2 : 3) === 2,'number ? ... : ...')
ok(({}     ? 2 : 3) === 2,'object ? ... : ...')

/* Tests 9-10: Shorting circuits */

function test1(x) { run1 = true; return 1 }
function test2(x) { run2 = true; return 2 }

run1 = run2 = false
ok((true ? test1() : test2 ()) === 1 && run2 === false,
	'true ? expr1 : expr2 does not evaluate expr2')
run1 = run2 = false
ok((false ? test1() : test2 ()) === 2 && run1 === false,
	'false ? expr1 : expr2 does not evaluate expr1')

// Test 11
// RT #79855: The run-time engine was confusing ‘term += term’ with
//           ‘term ? this : term’.  Internally the difference is
//            [term, '+=', term] vs [term, "this", term] and "this" was
//            being treated as an assignop like +=.
ok ((1 ? this : 1) === this, '... ? this : ...');
