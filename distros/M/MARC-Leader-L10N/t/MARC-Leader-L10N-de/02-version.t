use strict;
use warnings;

use MARC::Leader::L10N::de;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Leader::L10N::de::VERSION, 0.05, 'Version.');
