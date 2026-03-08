use strict;
use warnings;

use MARC::Validator::Plugin::Field045;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field045->new;
is($obj->name, 'field_045', 'Get name of plugin (field_045).');
