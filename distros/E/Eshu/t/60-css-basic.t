use strict;
use warnings;
use Test::More;
use Eshu;

# Simple rule
{
	my $input = <<'END';
body {
color: red;
font-size: 14px;
}
END

	my $expected = <<'END';
body {
	color: red;
	font-size: 14px;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'simple CSS rule');
}

# Already correct — idempotent
{
	my $input = <<'END';
body {
	color: red;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $input, 'already correct is idempotent');
}

# Multiple rules
{
	my $input = <<'END';
h1 {
color: blue;
}
p {
margin: 0;
}
END

	my $expected = <<'END';
h1 {
	color: blue;
}
p {
	margin: 0;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'multiple rules');
}

# Empty rule
{
	my $input = <<'END';
.empty {
}
END

	my $got = Eshu->indent_css($input);
	is($got, $input, 'empty rule block');
}

# Selector spanning multiple lines
{
	my $input = <<'END';
.foo,
.bar,
.baz {
color: red;
}
END

	my $expected = <<'END';
.foo,
.bar,
.baz {
	color: red;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'multi-line selector');
}

# With spaces option
{
	my $input = <<'END';
body {
color: red;
}
END

	my $expected = <<'END';
body {
    color: red;
}
END

	my $got = Eshu->indent_css($input, indent_char => ' ', indent_width => 4);
	is($got, $expected, 'spaces indentation');
}

# indent_string with lang css
{
	my $input = <<'END';
div {
padding: 0;
}
END

	my $expected = <<'END';
div {
	padding: 0;
}
END

	my $got = Eshu->indent_string($input, lang => 'css');
	is($got, $expected, 'indent_string with lang css');
}

# Blank lines preserved
{
	my $input = <<'END';
body {
color: red;
}

p {
margin: 0;
}
END

	my $expected = <<'END';
body {
	color: red;
}

p {
	margin: 0;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'blank lines preserved');
}

# calc() with nested parens — parens in values do not affect brace depth
{
	my $input = <<'END';
.box {
width: calc(100% - (2 * 16px));
height: calc(50vh - 20px);
}
END

	my $expected = <<'END';
.box {
	width: calc(100% - (2 * 16px));
	height: calc(50vh - 20px);
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'calc() with nested parens does not affect depth');
}

# var() custom property usage
{
	my $input = <<'END';
.text {
color: var(--primary);
font-size: var(--size, 16px);
margin: var(--spacing, 8px) 0;
}
END

	my $expected = <<'END';
.text {
	color: var(--primary);
	font-size: var(--size, 16px);
	margin: var(--spacing, 8px) 0;
}
END

	my $got = Eshu->indent_css($input);
	is($got, $expected, 'var() custom property usage');
}

done_testing();
