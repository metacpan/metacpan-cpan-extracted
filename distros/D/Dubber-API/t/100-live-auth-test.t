#!perl

use strict;
use warnings;

use Test::More;

use_ok('Dubber::API');

my $dubber_region = $ENV{'DUBBER_REGION'} || 'sandbox';
my $client_id     = $ENV{'DUBBER_CLIENT_ID'};
my $client_secret = $ENV{'DUBBER_CLIENT_SECRET'};
my $auth_id       = $ENV{'DUBBER_AUTH_ID'};
my $auth_secret   = $ENV{'DUBBER_AUTH_SECRET'};
my $debug         = $ENV{'DUBBER_DEBUG'} || 0;

SKIP:
{
    skip('Authentication info needs to be included in environment variables.')
        unless ( defined($client_id) and defined($client_secret) and defined($auth_id) and defined($auth_secret) );
    my $api = new_ok(
        'Dubber::API',
        [   region        => $dubber_region,
            client_id     => $client_id,
            client_secret => $client_secret,
            auth_id       => $auth_id,
            auth_secret   => $auth_secret,
            debug         => $debug,
        ]
    );

    ok( not( $api->_has_auth_token ), 'Not authenticated yet' );

    my $token = $api->auth_token;
    ok( defined($token), 'Got authentication token OK' );

    ok( $api->_has_auth_token, 'Is now authenticated' );
}
done_testing();
