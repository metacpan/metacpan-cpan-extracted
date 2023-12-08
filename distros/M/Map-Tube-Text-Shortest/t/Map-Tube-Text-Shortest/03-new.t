use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Map::Tube::Prague;
use Map::Tube::Text::Shortest;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Map::Tube::Text::Shortest->new(
	'tube' => Map::Tube::Prague->new,
);
isa_ok($obj, 'Map::Tube::Text::Shortest');

# Test.
eval {
	Map::Tube::Text::Shortest->new;
};
is($EVAL_ERROR, "Parameter 'tube' is required.\n",
	"Parameter 'tube' is required (undefined).");
clean();
