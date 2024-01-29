use strict;
use warnings;

use MARC::Leader::Print;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Leader::Print::VERSION, 0.04, 'Version.');
