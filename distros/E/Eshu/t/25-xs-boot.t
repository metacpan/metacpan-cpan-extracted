use strict;
use warnings;
use Test::More tests => 4;
use Eshu;

# BOOT section
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

BOOT:
printf("loading Foo\n");
HV *stash = gv_stashpv("Foo", GV_ADD);
newCONSTSUB(stash, "VERSION", newSVpv("1.0", 0));
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

BOOT:
	printf("loading Foo\n");
	HV *stash = gv_stashpv("Foo", GV_ADD);
	newCONSTSUB(stash, "VERSION", newSVpv("1.0", 0));
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'BOOT section at depth 0/1');
}

# BOOT with nested code
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

BOOT:
{
int i;
for (i = 0; i < 10; i++) {
printf("%d\n", i);
}
}
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

BOOT:
	{
		int i;
		for (i = 0; i < 10; i++) {
			printf("%d\n", i);
		}
	}
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'BOOT with nested C code');
}

# PROTOTYPES: ENABLE/DISABLE are module-level directives — column 0
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

PROTOTYPES: ENABLE

int
add(a, b)
int a
int b
CODE:
RETVAL = a + b;
OUTPUT:
RETVAL

PROTOTYPES: DISABLE

void
hide(x)
int x
CODE:
do_hide(x);
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

PROTOTYPES: ENABLE

int
add(a, b)
	int a
	int b
	CODE:
		RETVAL = a + b;
	OUTPUT:
		RETVAL

PROTOTYPES: DISABLE

void
hide(x)
	int x
	CODE:
		do_hide(x);
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'PROTOTYPES: ENABLE/DISABLE at column 0');
}

# VERSIONCHECK: DISABLE at module level
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

VERSIONCHECK: DISABLE

void
noop()
CODE:
return;
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

VERSIONCHECK: DISABLE

void
noop()
	CODE:
		return;
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'VERSIONCHECK: DISABLE at column 0');
}
