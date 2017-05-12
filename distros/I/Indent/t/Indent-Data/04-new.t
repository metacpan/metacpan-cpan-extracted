# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Indent::Data;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
eval {
	Indent::Data->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n");

# Test.
eval {
	Indent::Data->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n");

# Test.
eval {
	Indent::Data->new(
		'next_indent' => '  ',
		'line_size' => '1',
	);
};
is($EVAL_ERROR, "Bad line_size = '1' or length of string '  '.\n");

# Test.
my $obj = Indent::Data->new;
isa_ok($obj, 'Indent::Data');
