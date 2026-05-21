use strict;
use warnings;

use MARC::Validator::Plugin::Field080;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field080->new;
is($obj->name, 'field_080', 'Get name of plugin (field_080).');
