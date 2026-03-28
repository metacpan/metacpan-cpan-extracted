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

done_testing();
