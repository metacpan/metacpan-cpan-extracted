use strict;
use warnings;

use MARC::Validator::Plugin::Field080;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field080::VERSION, 0.15, 'Version.');
