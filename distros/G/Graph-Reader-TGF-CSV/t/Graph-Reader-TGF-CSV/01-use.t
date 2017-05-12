# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Graph::Reader::TGF::CSV');
}

# Test.
require_ok('Graph::Reader::TGF::CSV');
