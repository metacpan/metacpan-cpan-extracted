use strict;
use warnings;

use File::Find::Rule::BOM;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($File::Find::Rule::BOM::VERSION, 0.02, 'Version.');
