use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Map::Tube::Text::Shortest');
}

# Test.
require_ok('Map::Tube::Text::Shortest');
