use strict;
use warnings;
use Test::More;
use Eshu;

# Line comments
{
	my $input = <<'END';
function foo() {
// comment at top
var x = 1; // inline comment
return x;
}
END

	my $expected = <<'END';
function foo() {
	// comment at top
	var x = 1; // inline comment
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'line comments indented correctly');
}

# Line comment with braces
{
	my $input = <<'END';
function foo() {
// { should not increase depth
var x = 1;
// } should not decrease depth
return x;
}
END

	my $expected = <<'END';
function foo() {
	// { should not increase depth
	var x = 1;
	// } should not decrease depth
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'braces in line comments ignored');
}

# Block comments single-line
{
	my $input = <<'END';
function foo() {
/* single line block comment */
var x = 1;
return x;
}
END

	my $expected = <<'END';
function foo() {
	/* single line block comment */
	var x = 1;
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'single-line block comment');
}

# Block comments multi-line
{
	my $input = <<'END';
function foo() {
/*
 * Multi-line
 * block comment { with braces }
 */
var x = 1;
return x;
}
END

	my $expected = <<'END';
function foo() {
	/*
	* Multi-line
	* block comment { with braces }
	*/
	var x = 1;
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'multi-line block comment');
}

# JSDoc-style comments
{
	my $input = <<'END';
/**
 * @param {string} name
 * @returns {number}
 */
function foo(name) {
return name.length;
}
END

	my $expected = <<'END';
/**
* @param {string} name
* @returns {number}
*/
function foo(name) {
	return name.length;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'JSDoc-style comment');
}

# Comment after opening brace
{
	my $input = <<'END';
if (true) { // then
doSomething();
}
END

	my $expected = <<'END';
if (true) { // then
	doSomething();
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'comment after opening brace');
}

done_testing();
