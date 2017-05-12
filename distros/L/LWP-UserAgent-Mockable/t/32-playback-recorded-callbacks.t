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

my $pre_and_post = $ua->get( URL );
is( ref $pre_and_post, 'HTTP::Response', "Still get an HTTP response when using both pre- and post-callbacks" );
is( $pre_and_post->code, 999, "...and it returns the fake response from the post one" );

my $pre = $ua->get( URL );
is( ref $pre, 'HTTP::Response', 'Pre-callback returns HTTP response' );
is( $pre->code, 777, "...and it returns the fake response from the pre only, as no post" );

my $post = $ua->get( URL );
is( ref $post, 'HTTP::Response', 'Get an HTTP::Response from post-callback' );
is( $post->code, 999, '...and it returns the fake response' );

my $unfaked = $ua->get( URL );
isnt( $unfaked->code, 999, "No faking done after callback cleared" );

END {
    LWP::UserAgent::Mockable->finished;
}

done_testing();

