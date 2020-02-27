use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('File::Find::Rule::DMIDecode');
}

# Test.
require_ok('File::Find::Rule::DMIDecode');
