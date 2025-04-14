use strict;
use warnings;

use MARC::Leader::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Leader::Utils::VERSION, 0.01, 'Version.');
