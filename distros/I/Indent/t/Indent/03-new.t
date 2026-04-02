use strict;
use warnings;

use English qw(-no_match_vars);
use Indent;
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
eval {
	Indent->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n",
	"Unknown parameter ''.");

# Test.
eval {
	Indent->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");

# Test.
eval {
	Indent->new(
		'next_indent' => undef,
	);
};
is($EVAL_ERROR, "'next_indent' parameter must be defined.\n",
	"'next_indent' parameter must be defined.");

# Test.
eval {
	Indent->new(
		'next_indent' => {},
	);
};
is($EVAL_ERROR, "'next_indent' parameter must be a string.\n",
	"'next_indent' parameter must be a string.");

# Test.
eval {
	Indent->new(
		'next_indent' => \'',
	);
};
is($EVAL_ERROR, "'next_indent' parameter must be a string.\n",
	"'next_indent' parameter must be a string.");

# Test.
eval {
	Indent->new(
		'indent' => undef,
	);
};
is($EVAL_ERROR, "'indent' parameter must be defined.\n",
	"'indent' parameter must be defined.");

# Test.
eval {
	Indent->new(
		'indent' => {},
	);
};
is($EVAL_ERROR, "'indent' parameter must be a string.\n",
	"'indent' parameter must be a string.");

# Test.
eval {
	Indent->new(
		'indent' => \'',
	);
};
is($EVAL_ERROR, "'indent' parameter must be a string.\n",
	"'indent' parameter must be a string.");

# Test.
my $obj = Indent->new;
isa_ok($obj, 'Indent');
