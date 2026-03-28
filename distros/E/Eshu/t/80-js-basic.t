use strict;
use warnings;
use Test::More;
use Eshu;

# Basic brace nesting
{
	my $input = <<'END';
function foo() {
var x = 1;
if (x) {
bar();
}
return x;
}
END

	my $expected = <<'END';
function foo() {
	var x = 1;
	if (x) {
		bar();
	}
	return x;
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'basic function indentation');
}

# Nested functions
{
	my $input = <<'END';
function outer() {
function inner() {
return 1;
}
return inner();
}
END

	my $expected = <<'END';
function outer() {
	function inner() {
		return 1;
	}
	return inner();
}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'nested function indentation');
}

# Arrow functions
{
	my $input = <<'END';
const f = () => {
const x = 1;
return x;
};
END

	my $expected = <<'END';
const f = () => {
	const x = 1;
	return x;
};
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'arrow function indentation');
}

# Object literal
{
	my $input = <<'END';
const obj = {
a: 1,
b: {
c: 2,
d: 3,
},
};
END

	my $expected = <<'END';
const obj = {
	a: 1,
	b: {
		c: 2,
		d: 3,
	},
};
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'object literal indentation');
}

# Array nesting
{
	my $input = <<'END';
const arr = [
1,
[
2,
3,
],
4,
];
END

	my $expected = <<'END';
const arr = [
	1,
	[
		2,
		3,
	],
	4,
];
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'array nesting indentation');
}

# Empty lines preserved
{
	my $input = <<'END';
function foo() {

var x = 1;

return x;

}
END

	my $expected = <<'END';
function foo() {

	var x = 1;

	return x;

}
END

	my $got = Eshu->indent_js($input);
	is($got, $expected, 'empty lines preserved');
}

# Spaces mode
{
	my $input = <<'END';
function foo() {
bar();
}
END

	my $expected = <<'END';
function foo() {
    bar();
}
END

	my $got = Eshu->indent_js($input, indent_char => ' ', indent_width => 4);
	is($got, $expected, 'spaces mode with indent_width=4');
}

# detect_lang for JS extensions
{
	is(Eshu->detect_lang('app.js'),        'js', 'detect .js');
	is(Eshu->detect_lang('App.jsx'),       'js', 'detect .jsx');
	is(Eshu->detect_lang('module.mjs'),    'js', 'detect .mjs');
	is(Eshu->detect_lang('module.cjs'),    'js', 'detect .cjs');
	is(Eshu->detect_lang('app.ts'),        'js', 'detect .ts');
	is(Eshu->detect_lang('App.tsx'),       'js', 'detect .tsx');
	is(Eshu->detect_lang('types.mts'),     'js', 'detect .mts');
}

# indent_string dispatch
{
	my $input = "function f() {\nx = 1;\n}\n";
	my $expected = "function f() {\n\tx = 1;\n}\n";
	is(Eshu->indent_string($input, lang => 'js'), $expected, 'indent_string with lang=js');
	is(Eshu->indent_string($input, lang => 'javascript'), $expected, 'indent_string with lang=javascript');
	is(Eshu->indent_string($input, lang => 'ts'), $expected, 'indent_string with lang=ts');
	is(Eshu->indent_string($input, lang => 'typescript'), $expected, 'indent_string with lang=typescript');
}

done_testing();
