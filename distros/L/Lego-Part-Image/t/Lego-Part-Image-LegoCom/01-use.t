use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Lego::Part::Image::LegoCom');
}

# Test.
require_ok('Lego::Part::Image::LegoCom');
