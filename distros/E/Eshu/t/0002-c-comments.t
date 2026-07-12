use strict;
use warnings;
use Test::More;
use Eshu;

# Line comment — brace inside should be ignored
{
	my $input = <<'END';
void foo() {
// if (x) {
int y = 1;
}
END

	my $expected = <<'END';
void foo() {
	// if (x) {
	int y = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'line comment with brace ignored');
}

# Block comment — braces inside ignored
{
	my $input = <<'END';
void foo() {
/* { */
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	/* { */
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'single-line block comment with brace');
}

# Multi-line block comment
{
	my $input = <<'END';
void foo() {
/*
 * { this brace is in a comment }
 */
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	/*
	* { this brace is in a comment }
	*/
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'multi-line block comment');
}

# Block comment spanning code
{
	my $input = <<'END';
/* start
middle
end */
void foo() {
int x;
}
END

	my $expected = <<'END';
/* start
middle
end */
void foo() {
	int x;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'block comment at top level');
}

# Comment after code on same line
{
	my $input = <<'END';
void foo() {
int x = 1; /* init */
int y = 2; // next
}
END

	my $expected = <<'END';
void foo() {
	int x = 1; /* init */
	int y = 2; // next
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'inline comments preserved');
}

# Closing brace in comment should not affect depth
{
	my $input = <<'END';
void foo() {
int x = 1;
// }
int y = 2;
}
END

	my $expected = <<'END';
void foo() {
	int x = 1;
	// }
	int y = 2;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'closing brace in line comment ignored');
}

done_testing();
