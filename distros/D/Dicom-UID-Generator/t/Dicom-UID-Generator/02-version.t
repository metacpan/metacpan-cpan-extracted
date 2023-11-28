use strict;
use warnings;

use Dicom::UID::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Dicom::UID::Generator::VERSION, 0.02, 'Version.');
