use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Graph::Undirected;
use Map::Tube::Prague;
use Map::Tube::Graph;
use Test::MockObject;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
eval {
	Map::Tube::Graph->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", "Unknown parameter ''.");
clean();

# Test.
eval {
	Map::Tube::Graph->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");
clean();

# Test.
eval {
	Map::Tube::Graph->new;
};
is($EVAL_ERROR, "Parameter 'tube' is required.\n",
	"Parameter 'tube' is required.");
clean();

# Test.
eval {
	Map::Tube::Graph->new(
		'tube' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'tube' must be 'Map::Tube' object.\n",
	"Parameter 'tube' must be 'Map::Tube' object (string).");
clean();

# Test.
eval {
	Map::Tube::Graph->new(
		'tube' => Test::MockObject->new,
	);
};
is($EVAL_ERROR, "Parameter 'tube' must be 'Map::Tube' object.\n",
	"Parameter 'tube' must be 'Map::Tube' object (Test::MockObject).");
clean();

# Test.
my $obj = Map::Tube::Graph->new(
	'tube' => Map::Tube::Prague->new,
);
isa_ok($obj, 'Map::Tube::Graph', 'Instance with implicit Graph object.');
ok($obj->{'graph'}->is_directed, 'Is directed graph.');

# Test.
$obj = Map::Tube::Graph->new(
	'graph' => Graph::Undirected->new,
	'tube' => Map::Tube::Prague->new,
);
isa_ok($obj, 'Map::Tube::Graph', 'Instance with explicit Graph object.');
ok($obj->{'graph'}->is_undirected, 'Is undirected graph.');

# Test.
isa_ok($obj->graph, 'Graph', 'Test for callbacks.');
