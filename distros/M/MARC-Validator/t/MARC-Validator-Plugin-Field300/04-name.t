use strict;
use warnings;

use MARC::Validator::Plugin::Field300;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field300->new;
is($obj->name, 'field_300', 'Get name of plugin (field_300).');
