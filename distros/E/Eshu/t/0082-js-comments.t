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

# Lint-directive comments (eslint, @ts)
{
	my $input = <<'END';
function unsafe(input) {
// eslint-disable-next-line no-eval
const result = eval(input);
// @ts-ignore
return result.value;
}
END

	my $expected = <<'END';
function unsafe(input) {
	// eslint-disable-next-line no-eval
	const result = eval(input);
	// @ts-ignore
	return result.value;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'lint-directive comments treated as plain comments');
}

# TODO / FIXME comments
{
	my $input = <<'END';
class Widget {
render() {
// TODO: implement caching
// FIXME: handle null case
return this.buildDOM();
}
}
END

	my $expected = <<'END';
class Widget {
	render() {
		// TODO: implement caching
		// FIXME: handle null case
		return this.buildDOM();
	}
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'TODO/FIXME comments inside nested class method');
}

# Block comment with braces and code-like content
{
	my $input = <<'END';
/*
 * Example usage:
 *   if (x) {
 *     doSomething();
 *   }
 */
function doSomething() {
return true;
}
END

	my $expected = <<'END';
/*
* Example usage:
*   if (x) {
*     doSomething();
*   }
*/
function doSomething() {
	return true;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'block comment with code-like example braces');
}

done_testing();
