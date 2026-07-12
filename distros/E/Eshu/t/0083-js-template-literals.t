use strict;
use warnings;
use Test::More;
use Eshu;

# Simple template literal (single line)
{
	my $input = <<'END';
function foo() {
var x = `hello world`;
return x;
}
END

	my $expected = <<'END';
function foo() {
	var x = `hello world`;
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'single-line template literal');
}

# Template literal with interpolation (single line)
{
	my $input = <<'END';
function foo(name) {
var x = `hello ${name}!`;
return x;
}
END

	my $expected = <<'END';
function foo(name) {
	var x = `hello ${name}!`;
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'template literal with inline interpolation');
}

# Template literal with braces in interpolation
{
	my $input = <<'END';
function foo(items) {
var x = `count: ${items.filter(i => { return i > 0; }).length}`;
return x;
}
END

	my $expected = <<'END';
function foo(items) {
	var x = `count: ${items.filter(i => { return i > 0; }).length}`;
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'template literal with braces in interpolation');
}

# Template literal with comment-like content
{
	my $input = <<'END';
function foo() {
var x = `not a // comment and not /* this */ either`;
return x;
}
END

	my $expected = <<'END';
function foo() {
	var x = `not a // comment and not /* this */ either`;
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'comment-like content in template literal');
}

# Multi-line template literal (verbatim content)
{
	my $input = <<'END';
function foo() {
var x = `
  line one
    line two
`;
return x;
}
END

	my $expected = <<'END';
function foo() {
	var x = `
  line one
    line two
`;
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'multi-line template literal content preserved verbatim');
}

# Template after code resumes normal indentation
{
	my $input = <<'END';
function foo() {
var a = `template`;
if (true) {
var b = `another`;
}
}
END

	my $expected = <<'END';
function foo() {
	var a = `template`;
	if (true) {
		var b = `another`;
	}
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'normal indentation resumes after template literal');
}

# Template literals as object property values
{
	my $input = <<'END';
const obj = {
a: `hello ${name}`,
b: `world ${n + 1}`,
};
END

	my $expected = <<'END';
const obj = {
	a: `hello ${name}`,
	b: `world ${n + 1}`,
};
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'template literals as object property values');
}

# Template literal with ternary expression in interpolation
{
	my $input = <<'END';
function foo(x) {
var msg = `result: ${x > 0 ? 'pos' : 'neg'}`;
return msg;
}
END

	my $expected = <<'END';
function foo(x) {
	var msg = `result: ${x > 0 ? 'pos' : 'neg'}`;
	return msg;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'template literal with ternary in interpolation');
}

done_testing();
