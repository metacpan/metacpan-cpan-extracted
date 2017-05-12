# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::ErrorList;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::ErrorList::VERSION, 0.14, 'Version.');
