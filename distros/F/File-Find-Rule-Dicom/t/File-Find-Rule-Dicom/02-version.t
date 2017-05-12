# Pragmas.
use strict;
use warnings;

# Modules.
use File::Find::Rule::Dicom;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($File::Find::Rule::Dicom::VERSION, 0.04, 'Version.');
