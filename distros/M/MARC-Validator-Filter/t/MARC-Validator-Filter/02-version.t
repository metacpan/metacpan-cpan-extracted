use strict;
use warnings;

use MARC::Validator::Filter;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Filter::VERSION, 0.01, 'Version.');
