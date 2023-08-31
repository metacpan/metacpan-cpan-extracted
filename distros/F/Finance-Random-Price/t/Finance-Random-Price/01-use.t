use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Finance::Random::Price');
}

# Test.
require_ok('Finance::Random::Price');
