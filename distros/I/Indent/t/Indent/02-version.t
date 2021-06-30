use strict;
use warnings;

use Indent;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::VERSION, 0.08, 'Version.');
