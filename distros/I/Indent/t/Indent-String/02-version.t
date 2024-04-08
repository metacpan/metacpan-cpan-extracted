use strict;
use warnings;

use Indent::String;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::String::VERSION, 0.09, 'Version.');
