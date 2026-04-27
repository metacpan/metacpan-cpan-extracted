use strict;
use warnings;

use MARC::Field008::Print;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Field008::Print::VERSION, 0.01, 'Version.');
