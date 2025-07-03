use strict;
use warnings;

use MARC::Validator::Plugin::Field260;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field260->new;
is($obj->name, 'field_260', 'Get name of plugin (field_260).');
