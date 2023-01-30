use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Fedora::RPM::Spec::License');
}

# Test.
require_ok('Fedora::RPM::Spec::License');
