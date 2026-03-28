use strict;
use warnings;
use Test::More tests => 2;
use Eshu;

# Two XSUBs separated by blank line
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
add(a, b)
int a
int b
CODE:
RETVAL = a + b;
OUTPUT:
RETVAL

int
mul(a, b)
int a
int b
CODE:
RETVAL = a * b;
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
add(a, b)
	int a
	int b
	CODE:
		RETVAL = a + b;
	OUTPUT:
		RETVAL

int
mul(a, b)
	int a
	int b
	CODE:
		RETVAL = a * b;
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'two XSUBs separated by blank line');
}

# Three XSUBs, some with PREINIT
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
greet()
CODE:
printf("hello\n");

SV *
make_sv(str)
const char * str
CODE:
RETVAL = newSVpv(str, 0);
OUTPUT:
RETVAL

int
compute(x)
int x
PREINIT:
int tmp;
CODE:
tmp = x * x;
RETVAL = tmp + 1;
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

void
greet()
	CODE:
		printf("hello\n");

SV *
make_sv(str)
	const char * str
	CODE:
		RETVAL = newSVpv(str, 0);
	OUTPUT:
		RETVAL

int
compute(x)
	int x
	PREINIT:
		int tmp;
	CODE:
		tmp = x * x;
		RETVAL = tmp + 1;
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'three XSUBs with varied labels');
}
