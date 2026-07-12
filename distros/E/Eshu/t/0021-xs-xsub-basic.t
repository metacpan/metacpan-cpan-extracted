use strict;
use warnings;
use Test::More tests => 7;
use Eshu;

# Simple XSUB with CODE
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

SV *
get_value(self)
SV * self
CODE:
RETVAL = newSViv(42);
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

SV *
get_value(self)
	SV * self
	CODE:
		RETVAL = newSViv(42);
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'simple XSUB with CODE and OUTPUT');
}

# XSUB with PREINIT and INIT
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
add(a, b)
int a
int b
PREINIT:
int result;
INIT:
result = 0;
CODE:
result = a + b;
RETVAL = result;
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
add(a, b)
	int a
	int b
	PREINIT:
		int result;
	INIT:
		result = 0;
	CODE:
		result = a + b;
		RETVAL = result;
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'XSUB with PREINIT and INIT');
}

# XSUB with void return (no OUTPUT)
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
set_value(self, val)
SV * self
int val
CODE:
sv_setiv(self, val);
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

void
set_value(self, val)
	SV * self
	int val
	CODE:
		sv_setiv(self, val);
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'void XSUB with no OUTPUT');
}

# Idempotent — already correctly indented
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
double_it(x)
	int x
	CODE:
		RETVAL = x * 2;
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $input, 'already indented — idempotent');
}

# XSUB with CLEANUP section
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

SV *
new_object()
CODE:
RETVAL = newSV(0);
CLEANUP:
if (!RETVAL) croak("alloc failed");
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

SV *
new_object()
	CODE:
		RETVAL = newSV(0);
	CLEANUP:
		if (!RETVAL) croak("alloc failed");
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'XSUB with CLEANUP section');
}

# XSUB with POSTCALL section
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
call_hook(name)
const char * name
CODE:
invoke(name);
POSTCALL:
check_errors();
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

void
call_hook(name)
	const char * name
	CODE:
		invoke(name);
	POSTCALL:
		check_errors();
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'XSUB with POSTCALL section');
}

# PROTOTYPE: per-XSUB prototype declaration — should sit at label depth (1 tab),
# not be indented as a body line (2 tabs)
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
add(a, b)
int a
int b
PROTOTYPE: $$
CODE:
RETVAL = a + b;
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
add(a, b)
	int a
	int b
	PROTOTYPE: $$
	CODE:
		RETVAL = a + b;
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'PROTOTYPE: per-XSUB directive at label depth (1 tab)');
}
