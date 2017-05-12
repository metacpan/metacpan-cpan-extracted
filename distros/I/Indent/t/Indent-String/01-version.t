# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::String;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::String::VERSION, 0.03, 'Version.');
