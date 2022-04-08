use strict;
use warnings;

use LWP::Authen::OAuth2;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = LWP::Authen::OAuth2->new(
	client_id => 'Test',
	client_secret => 'Test',
        service_provider => 'Wikimedia',
);
isa_ok($obj, 'LWP::Authen::OAuth2');
my $sp = $obj->{service_provider};
is($sp->token_endpoint, 'https://meta.wikimedia.org/w/rest.php/oauth2/access_token', 'Token endpoint.');
is($sp->authorization_endpoint, 'https://meta.wikimedia.org/w/rest.php/oauth2/authorize', 'Authorization endpoint.');
