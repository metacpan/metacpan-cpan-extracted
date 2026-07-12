use strict;
use warnings;
use Test::More tests => 16;
use Eshu;

# Double-quoted string with braces
{
	my $input = <<'END';
sub foo {
my $x = "hello { world }";
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = "hello { world }";
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'DQ string with braces');
}

# Single-quoted string with braces
{
	my $input = <<'END';
sub foo {
my $x = 'hello { world }';
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = 'hello { world }';
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'SQ string with braces');
}

# Escaped quotes in DQ string
{
	my $input = <<'END';
sub foo {
my $x = "he said \"hello\" { }";
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = "he said \"hello\" { }";
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'escaped quotes in DQ string');
}

# Escaped quotes in SQ string
{
	my $input = <<'END';
sub foo {
my $x = 'it\'s a { test }';
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = 'it\'s a { test }';
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'escaped quotes in SQ string');
}

# String with parens and brackets
{
	my $input = <<'END';
sub foo {
my $x = "( [ ] )";
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = "( [ ] )";
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'string with parens and brackets');
}

# Multi-line DQ string — continuation lines must NOT be re-indented
# (adding whitespace would change the string's value)
{
	my $input = <<'END';
sub foo {
my $x = "hello
world";
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = "hello
world";
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multi-line DQ string: continuation verbatim');
}

# Adjacent strings
{
	my $input = <<'END';
sub foo {
my $x = "a" . 'b';
my $y = "c{d}" . 'e{f}';
}
END

	my $expected = <<'END';
sub foo {
	my $x = "a" . 'b';
	my $y = "c{d}" . 'e{f}';
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'adjacent strings with braces');
}

# Multi-line DQ string: pre-existing whitespace inside string preserved
{
	my $input = <<'END';
sub foo {
my $x = "hello
    world has spaces";
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = "hello
    world has spaces";
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multi-line DQ string: pre-existing whitespace in content preserved');
}

# Multi-line DQ string: idempotent when content already at column 0
{
	my $input = <<'END';
sub foo {
	my $x = "hello
world";
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $input, 'multi-line DQ string: idempotent');
}

# Multi-line SQ string: continuation verbatim
{
	my $input = <<'END';
sub foo {
my $x = 'line one
line two';
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = 'line one
line two';
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multi-line SQ string: continuation verbatim');
}

# Multi-line DQ string with brace-like content (braces in string must not affect depth)
{
	my $input = <<'END';
sub foo {
my $tmpl = "start {
nested { content }
}";
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $tmpl = "start {
nested { content }
}";
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multi-line DQ string: brace-like content verbatim, does not affect depth');
}

# Multi-line qq(): continuation verbatim
{
	my $input = <<'END';
sub foo {
my $x = qq(hello
world);
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = qq(hello
world);
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multi-line qq(): continuation verbatim');
}

# Multi-line q(): continuation verbatim
{
	my $input = <<'END';
sub foo {
my $x = q(hello
world);
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = q(hello
world);
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multi-line q(): continuation verbatim');
}

# Multi-line qq{}: continuation verbatim (braces in qq do not add code depth)
{
	my $input = <<'END';
sub foo {
my $x = qq{hello
world};
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = qq{hello
world};
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multi-line qq{}: continuation verbatim');
}

# Multi-line qq//: continuation verbatim
{
	my $input = <<'END';
sub foo {
my $x = qq/hello
world/;
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $x = qq/hello
world/;
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multi-line qq//: continuation verbatim');
}

# Multi-line qq(): SQL-like multiline with leading whitespace preserved
{
	my $input = <<'END';
sub foo {
my $sql = qq(SELECT *
FROM table
WHERE x = 1);
my $y = 1;
}
END

	my $expected = <<'END';
sub foo {
	my $sql = qq(SELECT *
FROM table
WHERE x = 1);
	my $y = 1;
}
END

	my $got = Eshu->indent_pl($input);
	is($got, $expected, 'multi-line qq(): sql-like content verbatim');
}
