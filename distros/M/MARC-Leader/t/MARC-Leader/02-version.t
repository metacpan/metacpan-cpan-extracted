use strict;
use warnings;

use MARC::Leader;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Leader::VERSION, 0.07, 'Version.');
