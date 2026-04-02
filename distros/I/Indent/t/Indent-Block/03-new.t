use strict;
use warnings;

use English qw(-no_match_vars);
use Indent::Block;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	Indent::Block->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n",
	"Unknown parameter ''.");

# Test.
eval {
	Indent::Block->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");

# Test.
my $obj = Indent::Block->new;
isa_ok($obj, 'Indent::Block');
