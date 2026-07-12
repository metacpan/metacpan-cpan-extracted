use strict;
use warnings;
use Test::More;
use Eshu;

plan tests => 6;

# 1. Range reindents only specified lines (C)
{
	my $input = "void foo() {\nint x = 1;\nint y = 2;\nint z = 3;\n}\n";
	my $result = Eshu->indent_c($input, range_start => 2, range_end => 3);
	my @lines = split /\n/, $result;
	is $lines[0], 'void foo() {', 'line 1 outside range: unchanged';
	is $lines[1], "\tint x = 1;", 'line 2 in range: reindented';
	is $lines[2], "\tint y = 2;", 'line 3 in range: reindented';
	is $lines[3], 'int z = 3;',  'line 4 outside range: unchanged';
}

# 2. Range 0,0 means all lines (default)
{
	my $input = "void foo() {\nint x = 1;\n}\n";
	my $all   = Eshu->indent_c($input);
	my $range = Eshu->indent_c($input, range_start => 0, range_end => 0);
	is $range, $all, 'range 0,0 same as no range';
}

# 3. Perl range preserves context
{
	my $input = "sub foo {\nmy \$x = 1;\nmy \$y = 2;\n}\n";
	my $result = Eshu->indent_pl($input, range_start => 2, range_end => 2);
	my @lines = split /\n/, $result;
	is $lines[1], "\tmy \$x = 1;", 'Perl range: line 2 reindented at correct depth';
}
