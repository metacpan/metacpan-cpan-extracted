use strict;
use warnings;
use Test::More tests => 2;
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
