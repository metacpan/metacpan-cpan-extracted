use strict;
use warnings;
use Test::More;
use Eshu;

# Simple regex literal
{
	my $input = <<'END';
function foo(s) {
var re = /hello/;
return re.test(s);
}
END

	my $expected = <<'END';
function foo(s) {
	var re = /hello/;
	return re.test(s);
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'simple regex literal');
}

# Regex with flags
{
	my $input = <<'END';
function foo(s) {
var re = /hello/gi;
return re.test(s);
}
END

	my $expected = <<'END';
function foo(s) {
	var re = /hello/gi;
	return re.test(s);
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'regex with flags');
}

# Regex with braces (quantifier)
{
	my $input = <<'END';
function foo(s) {
var re = /\d{3}-\d{4}/;
return re.test(s);
}
END

	my $expected = <<'END';
function foo(s) {
	var re = /\d{3}-\d{4}/;
	return re.test(s);
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'regex with brace quantifiers');
}

# Regex with character class
{
	my $input = <<'END';
function foo(s) {
var re = /[a-z{}/]+/;
return re.test(s);
}
END

	my $expected = <<'END';
function foo(s) {
	var re = /[a-z{}/]+/;
	return re.test(s);
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'regex with character class containing braces and slash');
}

# Division vs regex
{
	my $input = <<'END';
function foo(a, b) {
var x = a / b;
var y = /pattern/gi;
return x;
}
END

	my $expected = <<'END';
function foo(a, b) {
	var x = a / b;
	var y = /pattern/gi;
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'division vs regex context');
}

# Regex after operators
{
	my $input = <<'END';
function foo(s) {
if (/test/.test(s)) {
return true;
}
}
END

	my $expected = <<'END';
function foo(s) {
	if (/test/.test(s)) {
		return true;
	}
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'regex after opening paren');
}

# Regex character class with braces — must not affect depth
{
	my $input = <<'END';
function foo(s) {
var hasBrace = /[{}]/.test(s);
if (/^[{}\[\]]+$/.test(s)) {
return true;
}
return hasBrace;
}
END

	my $expected = <<'END';
function foo(s) {
	var hasBrace = /[{}]/.test(s);
	if (/^[{}\[\]]+$/.test(s)) {
		return true;
	}
	return hasBrace;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'regex character class with braces does not affect depth');
}

# Regex after return/case keywords
{
	my $input = <<'END';
function validate(type) {
switch (type) {
case 'email':
return /^[\w.@]+$/.test(type);
default:
return true;
}
}
END

	my $expected = <<'END';
function validate(type) {
	switch (type) {
		case 'email':
		return /^[\w.@]+$/.test(type);
		default:
		return true;
	}
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'regex after return/case keywords');
}

done_testing();
