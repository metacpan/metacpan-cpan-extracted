# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::DCMTK::DCMQRSCP::Config;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Dicom::DCMTK::DCMQRSCP::Config::VERSION, 0.03, 'Version.');
