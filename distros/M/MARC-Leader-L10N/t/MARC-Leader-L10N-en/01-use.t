use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('MARC::Leader::L10N::en');
}

# Test.
require_ok('MARC::Leader::L10N::en');
