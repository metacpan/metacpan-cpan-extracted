#!perl -T
do './t/jstest.pl' or die __DATA__

// ===================================================
// 15.1.1: Non-function global properties
// 9 tests
// ===================================================

ok(NaN != NaN, 'global NaN property')
ok(Infinity + Infinity == Infinity && Infinity > 0 === true,
	'global Infinity property');
ok(typeof undefined == 'undefined', 'global undefined property')

ok(!delete NaN, 'NaN cannot be deleted')
ok(!delete Infinity, 'Infinity cannot be deleted either')
ok(!delete undefined, 'nor can undefined')

NaN = 5;
is(NaN, 5, 'NaN is modifiable')
Infinity = 7
is(Infinity ,7, 'Infinity is modifiable, too')
undefined = 37
is(undefined, 37, 'so is undefined')
