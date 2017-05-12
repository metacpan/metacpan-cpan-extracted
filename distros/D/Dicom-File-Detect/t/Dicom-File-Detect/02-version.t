# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::File::Detect;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Dicom::File::Detect::VERSION, 0.03, 'Version.');
