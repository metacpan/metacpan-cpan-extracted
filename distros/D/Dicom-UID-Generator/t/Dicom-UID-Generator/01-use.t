# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Dicom::UID::Generator');
}

# Test.
require_ok('Dicom::UID::Generator');
