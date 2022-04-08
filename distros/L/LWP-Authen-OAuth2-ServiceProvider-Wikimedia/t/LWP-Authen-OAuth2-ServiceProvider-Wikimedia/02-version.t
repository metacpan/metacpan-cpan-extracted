use strict;
use warnings;

use LWP::Authen::OAuth2::ServiceProvider::Wikimedia;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($LWP::Authen::OAuth2::ServiceProvider::Wikimedia::VERSION, 0.01, 'Version.');
