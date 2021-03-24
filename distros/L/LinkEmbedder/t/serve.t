use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use LinkEmbedder;

$ENV{LINK_EMBEDDER_FORCE_SECURE} = 0;

my $link;
my $embedder = LinkEmbedder->new;
isa_ok($embedder->ua, 'Mojo::UserAgent');

use Mojolicious::Lite;
get '/example' => 'example';
get
  '/oembed' => [format => [qw(html json jsonp)]],
  {format => undef}, sub { $embedder->serve(shift) };
get '/header' => sub {
  my $c = shift;
  $c->res->headers->content_type('text/plain')->header('X-Provider-Name', 'Convos');
  $c->render(text => 'X-Provider-Name example');
};

my $t = Test::Mojo->new;
$t->get_ok('/example')->status_is(200);

$t->get_ok('/oembed?url=mailto:jhthorsen@cpan.org')->status_is(400)->json_is('/err', 400);
$t->get_ok("/oembed.jsonp?url=mailto:x")->status_is(400)->content_like(qr{^oembed\(\{"err":400\}\)$});
$t->get_ok("/oembed.jsonp?callback=cb&url=mailto:y")->status_is(400)->content_like(qr{^cb\(\{"err":400\}\)$});

my $url = $t->ua->server->url->clone->path('/example');
$t->get_ok("/oembed?url=$url")->status_is(200)->json_is('/title', 'example page');
$t->get_ok("/oembed.html?url=$url")->status_is(200)->text_is('h3', 'example page');
$t->get_ok("/oembed.jsonp?url=$url")->status_is(200)->content_like(qr{^oembed\(\{.*"title":"example page".*\}\)$});
$t->get_ok("/oembed.jsonp?callback=cb&url=$url")->status_is(200)
  ->content_like(qr{^cb\(\{.*"title":"example page".*\}\)$});

$url = $t->ua->server->url->clone->path('/header');
$t->get_ok("/oembed?url=$url")->status_is(200)->content_like(qr{class=\\"le-paste le-provider-convos le-rich\\"})
  ->content_like(qr{<pre>X-Provider-Name example});

done_testing;

__DATA__
@@ example.html.ep
<html>
<head>
<title>example page</title>
</head>
<body>
example!
</body>
</html>
