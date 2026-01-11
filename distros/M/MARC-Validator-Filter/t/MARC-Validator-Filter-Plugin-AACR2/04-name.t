use strict;
use warnings;

use MARC::Validator::Filter::Plugin::AACR2;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Filter::Plugin::AACR2->new;
is($obj->name, 'aacr2', 'Get name of plugin (aacr2).');
