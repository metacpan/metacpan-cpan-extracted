use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Error::Pure::Output::Tags::HTMLCustomPage');
}

# Test.
require_ok('Error::Pure::Output::Tags::HTMLCustomPage');
