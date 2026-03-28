use strict;
use warnings;
use Test::More tests => 4;
use Eshu;

# CODE label alignment
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
test()
CODE:
printf("hello\n");
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

void
test()
	CODE:
		printf("hello\n");
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'CODE label at depth 1');
}

# OUTPUT label alignment
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
get()
CODE:
RETVAL = 1;
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
get()
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'OUTPUT label at depth 1');
}

# CLEANUP label
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

SV *
fetch(key)
const char * key
PREINIT:
char *val;
CODE:
val = strdup(key);
RETVAL = newSVpv(val, 0);
OUTPUT:
RETVAL
CLEANUP:
free(val);
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

SV *
fetch(key)
	const char * key
	PREINIT:
		char *val;
	CODE:
		val = strdup(key);
		RETVAL = newSVpv(val, 0);
	OUTPUT:
		RETVAL
	CLEANUP:
		free(val);
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'CLEANUP label at depth 1');
}

# PPCODE label
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
get_pair()
PPCODE:
XPUSHs(sv_2mortal(newSViv(1)));
XPUSHs(sv_2mortal(newSViv(2)));
XSRETURN(2);
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

void
get_pair()
	PPCODE:
		XPUSHs(sv_2mortal(newSViv(1)));
		XPUSHs(sv_2mortal(newSViv(2)));
		XSRETURN(2);
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'PPCODE label at depth 1');
}
