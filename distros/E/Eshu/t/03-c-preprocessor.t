use strict;
use warnings;
use Test::More;
use Eshu;

# Basic #if/#endif — no pp indent (default)
{
	my $input = <<'END';
#ifdef FOO
void foo() {
int x;
}
#endif
END

	my $expected = <<'END';
#ifdef FOO
void foo() {
	int x;
}
#endif
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, '#ifdef/#endif at column 0 (default)');
}

# Nested #if/#else/#endif — no pp indent
{
	my $input = <<'END';
#ifdef A
#ifdef B
int x = 1;
#else
int x = 2;
#endif
#endif
END

	my $expected = <<'END';
#ifdef A
#ifdef B
int x = 1;
#else
int x = 2;
#endif
#endif
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'nested pp at column 0');
}

# With pp indent enabled
{
	my $input = <<'END';
#ifdef A
#ifdef B
int x = 1;
#else
int x = 2;
#endif
#endif
END

	my $expected = <<'END';
#ifdef A
	#ifdef B
int x = 1;
	#else
int x = 2;
	#endif
#endif
END

	my $got = Eshu->indent_c($input, indent_pp => 1);
	is($got, $expected, 'nested pp with indent_pp enabled');
}

# Preprocessor inside function
{
	my $input = <<'END';
void foo() {
#ifdef BAR
int x = 1;
#else
int x = 2;
#endif
}
END

	my $expected = <<'END';
void foo() {
#ifdef BAR
	int x = 1;
#else
	int x = 2;
#endif
}
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'pp directives inside function at column 0');
}

# #ifndef guard pattern
{
	my $input = <<'END';
#ifndef MY_H
#define MY_H

void foo();

#endif
END

	my $expected = <<'END';
#ifndef MY_H
#define MY_H

void foo();

#endif
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, 'header guard pattern unchanged');
}

# #if with expression
{
	my $input = <<'END';
#if PERL_VERSION >= 14
int x = 1;
#endif
END

	my $expected = <<'END';
#if PERL_VERSION >= 14
int x = 1;
#endif
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, '#if with expression');
}

# #elif
{
	my $input = <<'END';
#if defined(A)
int x = 1;
#elif defined(B)
int x = 2;
#else
int x = 3;
#endif
END

	my $expected = <<'END';
#if defined(A)
int x = 1;
#elif defined(B)
int x = 2;
#else
int x = 3;
#endif
END

	my $got = Eshu->indent_c($input);
	is($got, $expected, '#if/#elif/#else/#endif');
}

done_testing();
