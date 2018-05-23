#!perl -w
use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::HTTP::LocalServer;

my $ok = eval {
    require HTTP::Tiny::Paranoid;
    require Future::HTTP::Tiny::Paranoid;
    1;
};

my $server = Test::HTTP::LocalServer->spawn(
    #debug => 1
);
my $err = $@;
if( !$ok) {
    plan skip_all => "Couldn't load Future::HTTP::Tiny::Paranoid: $err";
    exit;
};

diag( "Version of HTTP::Tiny::Paranoid: " . HTTP::Tiny::Paranoid->VERSION );
my $url = $server->url;

# Check that the local / internal URL is whitelisted, for testing
my $h = $url->host;
#my $dns = Net::DNS::Paranoid->new(
#    whitelisted_hosts => [ $h, '127.0.0.1' ],
#);

HTTP::Tiny::Paranoid->whitelisted_hosts([ $h, '127.0.0.1' ]);

my $ua = Future::HTTP::Tiny::Paranoid->new();

my ($body,$headers) = $ua->http_get($url)->get;
like $headers->{Status}, qr/2../, "Retrieve URL using HTTP::Tiny::Paranoid backend";
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