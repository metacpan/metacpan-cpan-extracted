use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('File::Find::Rule::DWG');
}

# Test.
require_ok('File::Find::Rule::DWG');
