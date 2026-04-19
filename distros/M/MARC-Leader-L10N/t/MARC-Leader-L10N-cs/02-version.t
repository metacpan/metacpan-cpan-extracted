use strict;
use warnings;

use MARC::Leader::L10N::cs;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Leader::L10N::cs::VERSION, 0.05, 'Version.');
