# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::UID::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Dicom::UID::Generator::VERSION, 0.01, 'Version.');
