use strict;
use warnings;

use MARC::Validator::Plugin::Field008;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field008::VERSION, 0.05, 'Version.');
