use strict;
use warnings;

use MARC::Validator::Plugin::Field045;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field045::VERSION, 0.15, 'Version.');
