use strict;
use warnings;

use Dicom::DCMTK::DCMDump::Get;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Dicom::DCMTK::DCMDump::Get::VERSION, 0.04, 'Version.');
