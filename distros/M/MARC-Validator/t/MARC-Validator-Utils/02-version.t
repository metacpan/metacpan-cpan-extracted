use strict;
use warnings;

use MARC::Validator::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Utils::VERSION, 0.04, 'Version.');
