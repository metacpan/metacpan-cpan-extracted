# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Log::FreeSWITCH::Line::Data');
}

# Test.
require_ok('Log::FreeSWITCH::Line::Data');
