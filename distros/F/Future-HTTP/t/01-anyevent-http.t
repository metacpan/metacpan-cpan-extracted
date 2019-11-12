#!perl -w
use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::HTTP::LocalServer;

my $ok = eval {
    require Future::HTTP::AnyEvent;
    1;
};
my $err = $@;
if( !$ok) {
    plan skip_all => "Couldn't load Future::HTTP::AnyEvent: $err";
    exit;
};

delete @ENV{ qw[
    HTTP_PROXY
    http_proxy
    HTTP_PROXY_ALL
    http_proxy_all
    HTTPS_PROXY
    https_proxy
    CGI_HTTP_PROXY
    ALL_PROXY
    all_proxy
] };

diag( "Version of AnyEvent::HTTP: " . AnyEvent::HTTP->VERSION );

my $server = Test::HTTP::LocalServer->spawn(
    #debug => 1
);

my $ua = Future::HTTP::AnyEvent->new();
my $url = $server->url;

my ($body,$headers) = $ua->http_get($url)->get;
like $headers->{Status}, qr/2../, "Retrieve URL using AnyEvent::HTTP backend";
is $headers->{URL}, $server->url, "We arrive at the expected URL"
    or diag Dumper $headers;

my $u = $server->redirect( 'foo' );
($body,$headers) = $ua->http_get($u)->get;
like $headers->{Status}, qr/2../, "Retrieve URL using redirect for a single redirection";
is $headers->{URL}, $url . 'foo', "We arrive at the expected URL"
    or diag Dumper $headers;
ok exists $headers->{Redirect}, "We were redirected here";
ok !exists $headers->{Redirect}->[1]->{Redirect}, "... once";

$u = $server->redirect( 'redirect/foo' );
($body,$headers) = $ua->http_get($u)->get;
like $headers->{Status}, qr/2../, "Retrieve URL using redirect for a double redirection";
is $headers->{URL}, $url . 'foo', "We arrive at the expected URL"
    or diag Dumper $headers;
ok exists $headers->{Redirect}, "We were redirected here";
is $headers->{Redirect}->[1]->{Redirect}->[1]->{URL}, $u, "... twice, starting from $u"
    or diag Dumper $headers->{Redirect}->[1];

$server->stop;

done_testing;
