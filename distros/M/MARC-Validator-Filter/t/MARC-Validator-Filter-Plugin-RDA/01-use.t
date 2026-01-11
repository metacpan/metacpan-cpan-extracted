use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('MARC::Validator::Filter::Plugin::RDA');
}

# Test.
require_ok('MARC::Validator::Filter::Plugin::RDA');
