use strict;
use warnings;

use Error::Pure::Output::Tags::HTMLCustomPage;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::Output::Tags::HTMLCustomPage::VERSION, 0.04, 'Version.');
