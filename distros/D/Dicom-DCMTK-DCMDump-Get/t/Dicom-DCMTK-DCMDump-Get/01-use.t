# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Dicom::DCMTK::DCMDump::Get');
}

# Test.
require_ok('Dicom::DCMTK::DCMDump::Get');
