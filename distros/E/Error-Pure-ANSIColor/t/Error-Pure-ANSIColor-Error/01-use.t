use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Error::Pure::ANSIColor::Error');
}

# Test.
require_ok('Error::Pure::ANSIColor::Error');
