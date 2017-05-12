# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Output::Tags::HTMLCustomPage;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::Output::Tags::HTMLCustomPage::VERSION, 0.03, 'Version.');
