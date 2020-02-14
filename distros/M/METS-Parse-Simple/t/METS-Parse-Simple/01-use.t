use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('METS::Parse::Simple');
}

# Test.
require_ok('METS::Parse::Simple');
