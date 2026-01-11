use strict;
use warnings;

use MARC::Validator::Filter::Plugin::Material;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Filter::Plugin::Material::VERSION, 0.01, 'Version.');
