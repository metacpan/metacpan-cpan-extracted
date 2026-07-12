use strict;
use warnings;
use Test::More;
use Eshu;

plan tests => 4;

# 1. ALIAS section with mappings
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
length(self)
    SV *self
ALIAS:
    size = 1
    count = 2
CODE:
    RETVAL = 42;
OUTPUT:
    RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
length(self)
	SV *self
	ALIAS:
		size = 1
		count = 2
	CODE:
		RETVAL = 42;
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'ALIAS section with mappings');
}

# 2. INCLUDE directive
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

INCLUDE: const-xs.inc

void
hello()
CODE:
    printf("hello\n");
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

	INCLUDE: const-xs.inc

void
hello()
	CODE:
		printf("hello\n");
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'INCLUDE directive passthrough');
}

# 3. Preprocessor inside XS CODE section
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

int
get_value()
CODE:
#ifdef HAS_FEATURE
    RETVAL = feature_value();
#else
    RETVAL = default_value();
#endif
OUTPUT:
    RETVAL
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

int
get_value()
	CODE:
#ifdef HAS_FEATURE
		RETVAL = feature_value();
#else
		RETVAL = default_value();
#endif
	OUTPUT:
		RETVAL
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'preprocessor inside XS CODE section');
}

# 4. Multiple PACKAGE declarations
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
foo_method()
CODE:
    printf("foo\n");

MODULE = Foo  PACKAGE = Foo::Bar

void
bar_method()
CODE:
    printf("bar\n");
END

	my $expected = <<'END';
MODULE = Foo  PACKAGE = Foo

void
foo_method()
	CODE:
		printf("foo\n");

MODULE = Foo  PACKAGE = Foo::Bar

void
bar_method()
	CODE:
		printf("bar\n");
END

	my $got = Eshu->indent_xs($input);
	is($got, $expected, 'multiple PACKAGE declarations');
}
