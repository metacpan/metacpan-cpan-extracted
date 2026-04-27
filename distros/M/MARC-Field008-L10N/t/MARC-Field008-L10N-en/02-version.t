use strict;
use warnings;

use MARC::Field008::L10N::en;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Field008::L10N::en::VERSION, 0.01, 'Version.');
