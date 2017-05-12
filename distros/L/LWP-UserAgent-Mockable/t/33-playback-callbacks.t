#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{LWP_UA_MOCK}      = 'playback';
    $ENV{LWP_UA_MOCK_FILE} = 'callbacks.mockdata';

    # prevent failures if tests run in parallel
    plan skip_all => 'callbacks.mockdata missing' unless -e 'callbacks.mockdata';
}

use LWP;
use LWP::UserAgent::Mockable;
use Storable;

use constant URL => "http://google.com";

my $ua = LWP::UserAgent->new;
$ua->timeout( 3 );
$ua->env_proxy;

my $cb = sub {
    my ( $request, $response ) = @_;

    $response->code( $response->code - 1 );

    return $response;
};

LWP::UserAgent::Mockable->set_playback_callback( $cb );

my $original_is_999 = $ua->get( URL );
is( ref $original_is_999, 'HTTP::Response', "HTTP::Response returned" );
is( $original_is_999->code, 998, "...and it returns the modified response" );

# clear the callback
LWP::UserAgent::Mockable->set_playback_callback();

my $original_is_777 = $ua->get( URL );
is( ref $original_is_777, 'HTTP::Response', "HTTP::Response returned" );
is( $original_is_777->code, 777, "...and it is as the original" );

my $same;
my $validation_cb = sub {
    my ( $request, $mocked_request ) = @_;

    $same = $request->uri eq $mocked_request->uri ? 1 : 0;
};
LWP::UserAgent::Mockable->set_playback_validation_callback( $validation_cb );

my $validation_failure = $ua->get( "http://not_the_same_url" );
is( ref $validation_failure, 'HTTP::Response', "HTTP::Response returned" );
is( $validation_failure->code, 999, '...and it returns the expected response' );
is( $same, 0, "Requested URI isn't the one that was mocked" );

my $validation_success = $ua->get( URL );
is( ref $validation_success, 'HTTP::Response', "HTTP::Response returned" );
isnt( $validation_success->code, 999, "...and it returns the expected response" );
is( $same, 1, "Requested URI isthe one that was mocked" );

END {
    LWP::UserAgent::Mockable->finished;
}

done_testing();

