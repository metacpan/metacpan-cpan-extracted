use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('MARC::Validator::Plugin::Field040');
}

# Test.
require_ok('MARC::Validator::Plugin::Field040');
