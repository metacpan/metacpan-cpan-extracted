# Pragmas.
use strict;
use warnings;

# Modules.
use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Dicom::DCMTK::DCMQRSCP::Config', 'Dicom::DCMTK::DCMQRSCP::Config is covered.');
