# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Indent;
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
eval {
	Indent->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n");

# Test.
eval {
	Indent->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n");

# Test.
eval {
	Indent->new(
		'next_indent' => undef,
	);
};
is($EVAL_ERROR, "'next_indent' parameter must be defined.\n");

# Test.
eval {
	Indent->new(
		'next_indent' => {},
	);
};
is($EVAL_ERROR, "'next_indent' parameter must be a string.\n");

# Test.
eval {
	Indent->new(
		'next_indent' => \'',
	);
};
is($EVAL_ERROR, "'next_indent' parameter must be a string.\n");

# Test.
eval {
	Indent->new(
		'indent' => undef,
	);
};
is($EVAL_ERROR, "'indent' parameter must be defined.\n");

# Test.
eval {
	Indent->new(
		'indent' => {},
	);
};
is($EVAL_ERROR, "'indent' parameter must be a string.\n");

# Test.
eval {
	Indent->new(
		'indent' => \'',
	);
};
is($EVAL_ERROR, "'indent' parameter must be a string.\n");

# Test.
my $obj = Indent->new;
isa_ok($obj, 'Indent');
