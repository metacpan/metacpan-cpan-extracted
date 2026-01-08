use strict;
use warnings;

use MARC::Validator::Abstract;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Abstract::VERSION, 0.09, 'Version.');
