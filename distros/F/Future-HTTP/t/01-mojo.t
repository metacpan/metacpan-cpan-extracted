#!perl -w
use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::HTTP::LocalServer;

my $ok = eval {
    require Mojolicious;
    require Future::HTTP::Mojo;
    1;
};
my $err = $@;
if( !$ok) {
    plan skip_all => "Couldn't load Future::HTTP::Mojo: $err";
    exit;
};

plan tests => 11;

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

diag( "Version of Mojolicious: " . Mojolicious->VERSION );

my $server = Test::HTTP::LocalServer->spawn(
    #debug => 1
);

my $ua = Future::HTTP::Mojo->new();
my $url = "" . $server->url; # Mojolicious wants a string or a Mojo::URL, not a URI::URL :-/

my ($body,$headers) = $ua->http_get($url)->get;
like $headers->{Status}, qr/2../, "Retrieve URL using Mojo::UserAgent backend";
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

{
    my @warnings;
    local $SIG{__WARN__} = sub {
        push @warnings, $_[0];
        diag $_[0];
    };
    my $ua = Future::HTTP::Mojo->new();

    my $f = $ua->http_head(
      $url,
    )->then(sub {
      my $body = shift;
      Future->done($body);
    });

    my $result = $f->get;

    is 0+grep({/\b\QUse of uninitialized value \$chunk in concatenation\E\b/} @warnings),
        0, "No warnings when running (issue #2)" or diag Dumper \@warnings;
}
$server->stop;

done_testing;
