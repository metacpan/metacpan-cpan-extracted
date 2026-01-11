use strict;
use warnings;

use MARC::Validator::Filter::Abstract;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Filter::Abstract::VERSION, 0.01, 'Version.');
