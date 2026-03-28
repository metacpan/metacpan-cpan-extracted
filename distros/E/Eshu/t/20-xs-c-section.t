use strict;
use warnings;
use Test::More tests => 3;
use Eshu;

# C code above MODULE line gets C-style indentation
{
	my $input = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int helper(int x) {
int y = x + 1;
return y;
}

MODULE = Foo  PACKAGE = Foo
END

	my $expected = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int helper(int x) {
	int y = x + 1;
	return y;
}

MODULE = Foo  PACKAGE = Foo
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'C code above MODULE line');
}

# Nested C function above MODULE
{
	my $input = <<'END';
static void process(int *arr, int len) {
int i;
for (i = 0; i < len; i++) {
if (arr[i] > 0) {
arr[i] *= 2;
}
}
}

MODULE = Foo  PACKAGE = Foo
END

	my $expected = <<'END';
static void process(int *arr, int len) {
	int i;
	for (i = 0; i < len; i++) {
		if (arr[i] > 0) {
			arr[i] *= 2;
		}
	}
}

MODULE = Foo  PACKAGE = Foo
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'nested C function above MODULE');
}

# No C code — MODULE at top
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
hello()
	CODE:
		printf("hello\n");
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

void
hello()
	CODE:
		printf("hello\n");
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'MODULE at top, no C section');
}
