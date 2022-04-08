use strict;
use warnings;

use LWP::Authen::OAuth2::ServiceProvider::MediaWiki;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($LWP::Authen::OAuth2::ServiceProvider::MediaWiki::VERSION, 0.01, 'Version.');
