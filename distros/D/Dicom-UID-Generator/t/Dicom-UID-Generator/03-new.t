use strict;
use warnings;

use Dicom::UID::Generator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Dicom::UID::Generator->new;
isa_ok($obj, 'Dicom::UID::Generator');
