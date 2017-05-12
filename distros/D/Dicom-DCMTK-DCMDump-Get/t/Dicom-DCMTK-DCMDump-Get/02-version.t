# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::DCMTK::DCMDump::Get;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Dicom::DCMTK::DCMDump::Get::VERSION, 0.03, 'Version.');
