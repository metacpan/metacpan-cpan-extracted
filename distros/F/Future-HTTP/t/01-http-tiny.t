#!perl -w
use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::HTTP::LocalServer;

use Future::HTTP::Tiny;
use HTTP::Tiny;

my $server = Test::HTTP::LocalServer->spawn(
    #debug => 1
);

diag( "Version of HTTP::Tiny: " . HTTP::Tiny->VERSION );
my $ua = Future::HTTP::Tiny->new();
my $url = $server->url;

my ($body,$headers) = $ua->http_get($url)->get;
like $headers->{Status}, qr/2../, "Retrieve URL using HTTP::Tiny backend";
is $headers->{URL}, $server->url, "We arrive at the expected URL"
    or diag Dumper $headers;

my $u = $server->redirect( 'foo' );
($body,$headers) = $ua->http_get($u)->get;
like $headers->{Status}, qr/2../, "Retrieve URL using redirect for a single redirection";
# HTTP::Tiny 0.017 didn't record the final URL
if( $HTTP::Tiny::VERSION >= 0.018 ) {
    is $headers->{URL}, $url . 'foo', "We arrive at the expected URL"
        or diag Dumper $headers;
};
# The redirect detection only came with HTTP::Tiny 0.058+
if( $HTTP::Tiny::VERSION >= 0.058 ) {
    ok exists $headers->{Redirect}, "We were redirected here";
    ok !exists $headers->{Redirect}->[1]->{Redirect}, "... once";
};

$u = $server->redirect( 'redirect/foo' );
($body,$headers) = $ua->http_get($u)->get;
like $headers->{Status}, qr/2../, "Retrieve URL using redirect for a double redirection";
# HTTP::Tiny 0.017 didn't record the final URL
if( $HTTP::Tiny::VERSION >= 0.018 ) {
    is $headers->{URL}, $url . 'foo', "We arrive at the expected URL"
        or diag Dumper $headers;
};
# The redirect detection only came with HTTP::Tiny 0.058+
if( HTTP::Tiny->VERSION >= 0.058 ) {
    ok exists $headers->{Redirect}, "We were redirected here";
    is $headers->{Redirect}->[1]->{Redirect}->[1]->{URL}, $u, "... twice, starting from $u"
      or diag Dumper $headers->{Redirect}->[1];
};

$server->stop;

done_testing;