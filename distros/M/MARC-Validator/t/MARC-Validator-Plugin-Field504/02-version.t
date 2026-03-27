use strict;
use warnings;

use MARC::Validator::Plugin::Field504;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field504::VERSION, 0.14, 'Version.');
