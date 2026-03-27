use strict;
use warnings;

use MARC::Validator::Plugin::Field655;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field655::VERSION, 0.14, 'Version.');
