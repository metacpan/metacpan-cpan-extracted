use strict;
use warnings;

package LWP::Authen::OAuth2::ServiceProvider::MediaWikiImplementation;

use base qw(LWP::Authen::OAuth2::ServiceProvider::MediaWiki);

sub authorization_endpoint {
	return 'https://example.com/oauth2/authorize';
}

sub token_endpoint {
	return 'https://example.com/oauth2/access_token';
}

package main;

use English;
use Error::Pure::Utils qw(clean);
use LWP::Authen::OAuth2;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
eval {
	LWP::Authen::OAuth2->new(
		client_id => 'Test',
		client_secret => 'Test',
		service_provider => 'MediaWiki',
	);
};
like($EVAL_ERROR, qr{^Need to be implemented. End point oauth2/access_token.},
	'Need to be implemented token_endpoint() method.');
clean();

# Test.
## Hack for LWP::Authen::OAuth2::ServiceProvider::service_provider_class().
no warnings 'redefine';
*LWP::Authen::OAuth2::ServiceProvider::service_provider_class = sub {
	return 'LWP::Authen::OAuth2::ServiceProvider::MediaWikiImplementation';
};
my $obj = LWP::Authen::OAuth2->new(
	client_id => 'Test',
	client_secret => 'Test',
	service_provider => 'MediaWikiImplementation',
);
isa_ok($obj, 'LWP::Authen::OAuth2');
my $sp = $obj->{service_provider};
is($sp->token_endpoint, 'https://example.com/oauth2/access_token', 'Token endpoint.');
is($sp->authorization_endpoint, 'https://example.com/oauth2/authorize', 'Authorization endpoint.');
