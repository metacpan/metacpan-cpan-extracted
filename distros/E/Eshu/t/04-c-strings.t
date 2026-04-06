use strict;
use warnings;
use Test::More;
use Eshu;

# Double-quoted string with braces
{
	my $input = <<'END';
void foo() {
char *s = "{ not a block }";
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	char *s = "{ not a block }";
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'braces inside double-quoted string');
}

# Single-quoted char with brace
{
	my $input = <<'END';
void foo() {
char c = '{';
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	char c = '{';
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'brace in char literal');
}

# Escaped quote in string
{
	my $input = <<'END';
void foo() {
char *s = "hello \"world\" {";
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	char *s = "hello \"world\" {";
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'escaped quotes in string with brace');
}

# Escaped backslash before quote
{
	my $input = <<'END';
void foo() {
char *s = "path\\";
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	char *s = "path\\";
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'escaped backslash before closing quote');
}

# String with parens
{
	my $input = <<'END';
void foo() {
printf("(%d)", x);
int y = 1;
}
END

	my $expected = <<'END';
void foo() {
	printf("(%d)", x);
	int y = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'parens balanced including string literal');
}

# Empty string
{
	my $input = <<'END';
void foo() {
char *s = "";
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	char *s = "";
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'empty string literal');
}

# Char literal with escaped single quote
{
	my $input = <<'END';
void foo() {
char c = '\'';
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	char c = '\'';
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'escaped single quote in char literal');
}

# Wide string literal L"..."
{
	my $input = <<'END';
void foo() {
wchar_t *s = L"wide { string }";
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	wchar_t *s = L"wide { string }";
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'wide string literal L"..."');
}

# Adjacent string literals (C concatenation)
{
	my $input = <<'END';
void foo() {
const char *msg =
"part one "
"part { two } "
"part three";
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	const char *msg =
	"part one "
	"part { two } "
	"part three";
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'adjacent string literal concatenation');
}

# String with hex escape sequence
{
	my $input = <<'END';
void foo() {
const char *esc = "\x7b value \x7d";
int x = 1;
}
END

	my $expected = <<'END';
void foo() {
	const char *esc = "\x7b value \x7d";
	int x = 1;
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'string with hex escape sequences');
}

done_testing();
