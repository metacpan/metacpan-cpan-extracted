use strict;
use warnings;

use Indent::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::Utils::VERSION, 0.09, 'Version.');
