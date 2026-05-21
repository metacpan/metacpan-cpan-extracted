#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::More tests => 16;
use Test::Builder::Tester;
use Test::Color;

test_out("ok 1 - is_tuple runs");
is_tuple([1,1,1], [1,1,1], [qw/r g b/], 'is_tuple runs');
test_test("simplest is_tuple case runs");

test_out("not ok 1");
test_err("# 'is_tuple' got not enough arguments");
test_fail(+1);
is_tuple([1,1,1], [1,1,1], [qw/r g b/]);
test_test("is_tuple checks if it got enough arguments");

test_out("not ok 1 - C");
test_err("# failed test: C - got no values (need an ARRAY ref)");
test_fail(+1);
is_tuple(undef, [1,1,1], [qw/r g b/], 'C');
test_test("is_tuple checks if got any defined values");

test_out("not ok 1 - D");
test_err("# failed test: D - got values: '1' that are not a tuple (ARRAY ref)");
test_fail(+1);
is_tuple(1, [1,1,1], [qw/r g b/], 'D');
test_test("is_tuple checks if got values in an ARRAY");

test_out("not ok 1 - E");
test_err("# failed test: E - got no expected values (need an ARRAY ref)");
test_fail(+1);
is_tuple([1,1,1], undef, [qw/r g b/], 'E');
test_test("is_tuple checks if got any defined values to expect");

test_out("not ok 1 - F");
test_err("# failed test: F - expected values: '1' are not a tuple (ARRAY ref)");
test_fail(+1);
is_tuple([1,1,1], 1, [qw/r g b/], 'F');
test_test("is_tuple checks if expected values are in an ARRAY");

test_out("not ok 1 - G");
test_err("# failed test: G - got no axis names (need an ARRAY ref)");
test_fail(+1);
is_tuple([1,1,1], [1,1,1], undef, 'G');
test_test("is_tuple checks if names names are defined");

test_out("not ok 1 - H");
test_err("# failed test: H - axis names: 'red' are not in a tuple (ARRAY ref)");
test_fail(+1);
is_tuple([1,1,1], [1,1,1], 'red', 'H');
test_test("is_tuple checks if axis names are in an ARRAY");

test_out("not ok 1");
test_err("# got no test name");
test_fail(+1);
is_tuple([1,1,1], [1,1,1], [qw/r g b/], undef);
test_test("is_tuple checks if test name is defined");

test_out("not ok 1 - J");
test_err("# failed test: J - expected 3 values (axis count) in tuple, but got 4");
test_fail(+1);
is_tuple([1,1,1,1], [1,1,1], [qw/r g b/], 'J');
test_test("is_tuple checks if result tuple has right amount of values");

test_out("not ok 1 - K");
test_err("# failed test: K - need 3 values (axis count) to compare with (expect), but got 2");
test_fail(+1);
is_tuple([1,1,1], [1,1], [qw/r g b/], 'K');
test_test("is_tuple checks if expected tuple has right amount of values");

test_out("not ok 1 - L");
test_err("# failed test: L - red value I got is not a number");
test_fail(+1);
is_tuple(['-',1,1], [1,1,1], [qw/red g b/], 'L');
test_test("is_tuple reports first value is not a number");

test_out("not ok 1 - M");
test_err("# failed test: M - expected r value of 1 but got 0.9");
test_fail(+1);
is_tuple([0.9,1,1], [1,1,1], [qw/r g b/], 'M');
test_test("is_tuple reports first value is not as expected");

test_out("not ok 1 - N");
test_err("# failed test: N - red value I got is not a number, green value I got is not a number, blue value I got is not a number");
test_fail(+1);
is_tuple(['-','1.','2b'], [1,1,1], [qw/red green blue/], 'N');
test_test("is_tuple reports all values are not numbers");

test_out("not ok 1 - O");
test_err("# failed test: O - expected g value of 1 but got 0.1, expected b value of 1 but got 0.2");
test_fail(+1);
is_tuple([1,.1,.2], [1,1,1], [qw/r g b/], 'O');
test_test("is_tuple reports two values are not as expected");

test_out("not ok 1 - P");
test_err("# failed test: P - expected r value of 1 but got 0, expected g value of 1 but got 0, expected b value of 1 but got 0");
test_fail(+1);
is_tuple([0,0,0], [1,1,1], [qw/r g b/], 'P');
test_test("is_tuple reports all values are not as expected");

done_testing;

