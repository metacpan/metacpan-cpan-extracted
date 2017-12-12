#!perl -w
use strict;
use warnings;
use Data::Dumper;

use Test::More;
use lib 'inc';
use Test::HTTP::LocalServer;

my $ok = eval {
    require Net::Async::HTTP;
	require Future::HTTP::NetAsync;
    1;
};
my $err = $@;
if( !$ok) {
    plan skip_all => "Couldn't load Net::Async::HTTP: $err";
    exit;
};

diag( "Version of Net::Async::HTTP: " . Net::Async::HTTP->VERSION );

my $server = Test::HTTP::LocalServer->spawn(
    #debug => 1
);

my $ua = Future::HTTP::NetAsync->new();
my $url = $server->url;

my ($body,$headers) = $ua->http_get($url)->get;
like $headers->{Status}, qr/2../, "Retrieve URL using Net::Async::HTTP backend";
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