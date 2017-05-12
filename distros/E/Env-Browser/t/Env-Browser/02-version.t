# Pragmas.
use strict;
use warnings;

# Modules.
use Env::Browser;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Env::Browser::VERSION, 0.05, 'Version.');
