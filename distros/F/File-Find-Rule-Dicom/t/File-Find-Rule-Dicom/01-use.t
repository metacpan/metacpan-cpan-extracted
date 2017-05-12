# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('File::Find::Rule::Dicom');
}

# Test.
require_ok('File::Find::Rule::Dicom');
