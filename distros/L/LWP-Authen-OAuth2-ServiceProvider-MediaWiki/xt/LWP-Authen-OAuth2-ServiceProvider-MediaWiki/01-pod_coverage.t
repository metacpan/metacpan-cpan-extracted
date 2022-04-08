use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('LWP::Authen::OAuth2::ServiceProvider::MediaWiki', 'LWP::Authen::OAuth2::ServiceProvider::MediaWiki is covered.');
