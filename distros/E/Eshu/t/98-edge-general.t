use strict;
use warnings;
use Test::More tests => 5;
use Eshu;

# Empty C input
{
	my $result = Eshu->indent_c('');
	is($result, '', 'empty C input produces empty output');
}

# Empty JS input
{
	my $result = Eshu->indent_js('');
	is($result, '', 'empty JS input produces empty output');
}

# CRLF line endings in Perl — content correctly indented
{
	my $input  = "sub foo {\r\nmy \$x = 1;\r\n}\r\n";
	my $result = Eshu->indent_pl($input);
	(my $norm  = $result) =~ s/\r//g;
	is($norm, "sub foo {\n\tmy \$x = 1;\n}\n", 'CRLF input correctly indented (Perl)');
}

# CRLF line endings in C — content correctly indented
{
	my $input  = "void foo() {\r\nint x = 1;\r\n}\r\n";
	my $result = Eshu->indent_c($input);
	(my $norm  = $result) =~ s/\r//g;
	is($norm, "void foo() {\n\tint x = 1;\n}\n", 'CRLF input correctly indented (C)');
}

# File with only blank lines preserved as-is
{
	my $input  = "\n\n\n";
	my $result = Eshu->indent_pl($input);
	is($result, "\n\n\n", 'blank-only input preserved');
}
