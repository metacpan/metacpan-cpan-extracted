use strict;
use warnings;

use MARC::Validator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::VERSION, 0.06, 'Version.');
