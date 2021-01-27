use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Graph::Reader::UnicodeTree');
}

# Test.
require_ok('Graph::Reader::UnicodeTree');
