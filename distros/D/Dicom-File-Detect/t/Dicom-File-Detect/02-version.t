use strict;
use warnings;

use Dicom::File::Detect;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Dicom::File::Detect::VERSION, 0.05, 'Version.');
