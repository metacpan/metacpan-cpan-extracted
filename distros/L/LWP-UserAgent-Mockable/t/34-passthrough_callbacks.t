#!perl

BEGIN {
    $ENV{ LWP_UA_MOCK } = 'passthrough';
}

use strict;
use warnings;

use LWP;
use LWP::UserAgent::Mockable;
use Storable;
use Test::More;

use constant URL => "http://google.com";

my $pre_cb = sub {
    my ( $request ) = @_;

    my $response = HTTP::Response->new;
    $response->code( 777 );
    $response->content( "boogleboo" );

    return $response;
};

my $cb = sub {
    my ( $request, $response ) = @_;

    $response->content( "This isn't the URL you're looking for" );
    $response->code( 999 );

    return $response;
};

LWP::UserAgent::Mockable->set_record_callback( $cb );
LWP::UserAgent::Mockable->set_record_pre_callback( $pre_cb );

my $ua = LWP::UserAgent->new;

$ua->timeout( 3 );
$ua->env_proxy;

my $pre_and_post = $ua->get( URL );
is( ref $pre_and_post, 'HTTP::Response', "Still get an HTTP response when using both pre- and post-callbacks" );
is( $pre_and_post->code, 999, "...and it returns the fake response from the post one" );

# clear the post callback, pre callback is still in-effect
LWP::UserAgent::Mockable->set_record_callback();

my $pre = $ua->get( URL );
is( ref $pre, 'HTTP::Response', 'Pre-callback returns HTTP response' );
is( $pre->code, 777, "...and it returns the fake response from the pre only, as no post" );

# clear the pre-callback also, subsequent requests will not be faked
LWP::UserAgent::Mockable->set_record_pre_callback();

# re-apply the post callback, so have that one only
LWP::UserAgent::Mockable->set_record_callback( $cb );

my $post = $ua->get( URL );
is( ref $post, 'HTTP::Response', 'Get an HTTP::Response from post-callback' );
is( $post->code, 999, '...and it returns the fake response' );

# re-apply the post callback, so have that one only
LWP::UserAgent::Mockable->set_record_callback();

my $unfaked = $ua->get( URL );
isnt( $unfaked->code, 999, "No faking done after callback cleared" );

# create a pre-callback that doesn't return an HTTP::Response
LWP::UserAgent::Mockable->set_record_pre_callback( sub { return undef } );

my $no_response_returned;
eval {
    $no_response_returned = $ua->get( URL );
};
ok( defined $@, "Error is thrown when pre-callback doesn't return an HTTP::Response object" );

LWP::UserAgent::Mockable->set_record_pre_callback();

# and finally, create a post-callback that doesn't return an HTTP::Response
LWP::UserAgent::Mockable->set_record_callback( sub { return undef } );
my $no_response_returned_post;
eval {
    $no_response_returned_post = $ua->get( URL );
};
ok( defined $@, "Error is thrown when post-callback doesn't return an HTTP::Response object" );

END {
    LWP::UserAgent::Mockable->finished;
}

done_testing();

