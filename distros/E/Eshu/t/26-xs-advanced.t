use strict;
use warnings;
use Test::More;
use Eshu;

# ALIAS: multiple names for one XSUB
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
is_valid(self)
SV * self
ALIAS:
is_ok = 1
is_good = 2
CODE:
RETVAL = SvOK(self) ? 1 : 0;
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
is_valid(self)
	SV * self
	ALIAS:
		is_ok = 1
		is_good = 2
	CODE:
		RETVAL = SvOK(self) ? 1 : 0;
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'XSUB with ALIAS section');
}

# INPUT: section with type override
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
process(buf, len)
SV * buf
int len
INPUT:
buf
CODE:
RETVAL = do_process(SvPV_nolen(buf), len);
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
process(buf, len)
	SV * buf
	int len
	INPUT:
	buf
	CODE:
		RETVAL = do_process(SvPV_nolen(buf), len);
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'XSUB with INPUT section');
}

# XSUB with nested C control flow in CODE
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
count_matches(str, pat)
const char * str
const char * pat
CODE:
int count = 0;
const char *p = str;
while (*p) {
if (*p == *pat) {
count++;
}
p++;
}
RETVAL = count;
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
count_matches(str, pat)
	const char * str
	const char * pat
	CODE:
		int count = 0;
		const char *p = str;
		while (*p) {
			if (*p == *pat) {
				count++;
			}
			p++;
		}
		RETVAL = count;
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'XSUB with nested C control flow in CODE');
}

# XSUB with PPCODE (list context)
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
get_pair(self)
SV * self
PPCODE:
XPUSHs(sv_2mortal(newSVpvs("key")));
XPUSHs(sv_2mortal(newSViv(42)));
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

void
get_pair(self)
	SV * self
	PPCODE:
		XPUSHs(sv_2mortal(newSVpvs("key")));
		XPUSHs(sv_2mortal(newSViv(42)));
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'XSUB with PPCODE for list context');
}

done_testing();
