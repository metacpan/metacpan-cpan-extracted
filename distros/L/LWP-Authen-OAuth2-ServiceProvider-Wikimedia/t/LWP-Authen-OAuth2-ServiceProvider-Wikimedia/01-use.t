use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('LWP::Authen::OAuth2::ServiceProvider::Wikimedia');
}

# Test.
require_ok('LWP::Authen::OAuth2::ServiceProvider::Wikimedia');
