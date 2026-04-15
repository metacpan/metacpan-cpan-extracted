use strict;
use warnings;

use MARC::Leader::L10N::en;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Leader::L10N::en::VERSION, 0.02, 'Version.');
