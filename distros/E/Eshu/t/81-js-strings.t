use strict;
use warnings;
use Test::More;
use Eshu;

# Double-quoted strings with braces inside
{
	my $input = <<'END';
function foo() {
var x = "hello { world }";
var y = "nested { { } }";
return x;
}
END

	my $expected = <<'END';
function foo() {
	var x = "hello { world }";
	var y = "nested { { } }";
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'braces in double-quoted strings ignored');
}

# Single-quoted strings with braces inside
{
	my $input = <<'END';
function foo() {
var x = 'hello { world }';
var y = 'with "quotes" inside';
return x;
}
END

	my $expected = <<'END';
function foo() {
	var x = 'hello { world }';
	var y = 'with "quotes" inside';
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'braces in single-quoted strings ignored');
}

# Escaped quotes in strings
{
	my $input = <<'END';
function foo() {
var x = "escaped \" quote { }";
var y = 'escaped \' quote { }';
return x;
}
END

	my $expected = <<'END';
function foo() {
	var x = "escaped \" quote { }";
	var y = 'escaped \' quote { }';
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'escaped quotes in strings');
}

# Strings with escape sequences
{
	my $input = <<'END';
function foo() {
var x = "line1\nline2\ttab";
var y = "backslash \\\\ end";
return x;
}
END

	my $expected = <<'END';
function foo() {
	var x = "line1\nline2\ttab";
	var y = "backslash \\\\ end";
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'escape sequences in strings');
}

# String with comment-like content
{
	my $input = <<'END';
function foo() {
var x = "not a // comment";
var y = "not a /* comment */";
return x;
}
END

	my $expected = <<'END';
function foo() {
	var x = "not a // comment";
	var y = "not a /* comment */";
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'comment-like content in strings ignored');
}

done_testing();
