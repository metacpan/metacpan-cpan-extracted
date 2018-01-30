# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Output::Text;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::Output::Text::VERSION, 0.23, 'Version.');
