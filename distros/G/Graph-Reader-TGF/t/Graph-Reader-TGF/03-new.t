use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Graph::Reader::TGF;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Graph::Reader::TGF->new;
isa_ok($obj, 'Graph::Reader::TGF');

# Test.
eval {
	Graph::Reader::TGF->new(
		'vertex_callback' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'vertex_callback' isn't reference to code.\n",
	"Parameter 'vertex_callback' isn't reference to code.");
clean();

# Test.
eval {
	Graph::Reader::TGF->new(
		'edge_callback' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'edge_callback' isn't reference to code.\n",
	"Parameter 'edge_callback' isn't reference to code.");
clean();
