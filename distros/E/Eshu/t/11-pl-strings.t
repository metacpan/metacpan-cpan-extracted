use strict;
use warnings;
use Test::More tests => 7;
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

# Multi-line string (each line re-indented)
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
	is($got, $expected, 'multi-line DQ string');
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
