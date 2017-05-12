# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Lego::Part::Image::PeeronCom');
}

# Test.
require_ok('Lego::Part::Image::PeeronCom');
