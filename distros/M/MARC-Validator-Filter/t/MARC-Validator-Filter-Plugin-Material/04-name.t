use strict;
use warnings;

use MARC::Validator::Filter::Plugin::Material;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Filter::Plugin::Material->new;
is($obj->name, 'material', 'Get name of plugin (material).');
