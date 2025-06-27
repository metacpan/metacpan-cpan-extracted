use strict;
use warnings;

use MARC::Field008;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Field008::VERSION, 0.03, 'Version.');
