use strict;
use warnings;

use MARC::Validator::Filter::Plugin::RDA;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Filter::Plugin::RDA::VERSION, 0.01, 'Version.');
