use strict;
use warnings;
use Test::More;
use Eshu;

plan tests => 5;

# 1. C — trailing spaces stripped
{
	my $input = "if (x) {  \n\tx = 1;   \n}  \n";
	my $result = Eshu->indent_c($input);
	unlike $result, qr/[ \t]+\n/, 'C: no trailing whitespace on any line';
}

# 2. Perl — trailing spaces stripped
{
	my $input = "sub foo {  \n\tmy \$x = 1;   \n}  \n";
	my $result = Eshu->indent_pl($input);
	unlike $result, qr/[ \t]+\n/, 'Perl: no trailing whitespace on any line';
}

# 3. XS — trailing spaces stripped
{
	my $input = <<'END';
MODULE = Foo  PACKAGE = Foo

void
hello(name)
	const char * name
	CODE:
		printf("hello %s\n", name);
	OUTPUT:
		RETVAL
END
	my $result = Eshu->indent_string($input, lang => 'xs');
	unlike $result, qr/[ \t]+\n/, 'XS: no trailing whitespace on any line';
}

# 4. Empty lines stay empty (no indent-only lines)
{
	my $input = "if (x) {\n\n\tx = 1;\n}\n";
	my $result = Eshu->indent_c($input);
	unlike $result, qr/^[ \t]+$/m, 'empty lines have no whitespace';
}

# 5. Content after stripping is correct
{
	my $input = "void foo() {  \n  x = 1;   \n}  \n";
	my $expected = "void foo() {\n\tx = 1;\n}\n";
	my $result = Eshu->indent_c($input);
	is $result, $expected, 'trailing ws stripped and indent corrected';
}
