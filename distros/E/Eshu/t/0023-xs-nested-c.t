use strict;
use warnings;
use Test::More tests => 3;
use Eshu;

# if/else inside CODE block
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
clamp(val, lo, hi)
int val
int lo
int hi
CODE:
if (val < lo) {
RETVAL = lo;
} else if (val > hi) {
RETVAL = hi;
} else {
RETVAL = val;
}
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
clamp(val, lo, hi)
	int val
	int lo
	int hi
	CODE:
		if (val < lo) {
			RETVAL = lo;
		} else if (val > hi) {
			RETVAL = hi;
		} else {
			RETVAL = val;
		}
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'if/else inside CODE block');
}

# Nested for loop in CODE
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
fill(arr, n)
int * arr
int n
CODE:
{
int i;
for (i = 0; i < n; i++) {
arr[i] = i * 2;
}
}
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

void
fill(arr, n)
	int * arr
	int n
	CODE:
		{
			int i;
			for (i = 0; i < n; i++) {
				arr[i] = i * 2;
			}
		}
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'nested for loop in CODE');
}

# Switch inside CODE
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

const char *
name(code)
int code
CODE:
switch (code) {
case 0:
RETVAL = "zero";
break;
case 1:
RETVAL = "one";
break;
default:
RETVAL = "other";
break;
}
OUTPUT:
RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

const char *
name(code)
	int code
	CODE:
		switch (code) {
			case 0:
			RETVAL = "zero";
			break;
			case 1:
			RETVAL = "one";
			break;
			default:
			RETVAL = "other";
			break;
		}
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'switch inside CODE');
}
