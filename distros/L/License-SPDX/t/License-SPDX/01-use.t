use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('License::SPDX');
}

# Test.
require_ok('License::SPDX');
