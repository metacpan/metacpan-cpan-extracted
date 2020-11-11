use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Map::Tube::Prague;
use Map::Tube::GraphViz;
use Test::MockObject;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
eval {
	Map::Tube::GraphViz->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");
clean();

# Test.
eval {
	Map::Tube::GraphViz->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");
clean();

# Test.
eval {
	Map::Tube::GraphViz->new;
};
is($EVAL_ERROR, "Parameter 'tube' is required.\n",
	"Parameter 'tube' is required.");
clean();

# Test.
eval {
	Map::Tube::GraphViz->new(
		'tube' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'tube' must be 'Map::Tube' object.\n",
	"Parameter 'tube' must be 'Map::Tube' object (string).");
clean();

# Test.
eval {
	Map::Tube::GraphViz->new(
		'tube' => Test::MockObject->new,
	);
};
is($EVAL_ERROR, "Parameter 'tube' must be 'Map::Tube' object.\n",
	"Parameter 'tube' must be 'Map::Tube' object (Test::MockObject).");
clean();

# Test.
my $obj = Map::Tube::GraphViz->new(
	'tube' => Map::Tube::Prague->new,
);
isa_ok($obj, 'Map::Tube::GraphViz');
