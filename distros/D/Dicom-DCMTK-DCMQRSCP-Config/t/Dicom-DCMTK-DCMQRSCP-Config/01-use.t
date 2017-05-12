# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Dicom::DCMTK::DCMQRSCP::Config');
}

# Test.
require_ok('Dicom::DCMTK::DCMQRSCP::Config');
