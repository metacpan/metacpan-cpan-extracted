use strict;
use warnings;

use MARC::Validator::Plugin::Field300;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field300::VERSION, 0.14, 'Version.');
