use lib 'lib';
use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('http://xkcd.com/927')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Xkcd');
is_deeply $link->TO_JSON,
  {
  cache_age     => 0,
  height        => 0,
  html          => photo_html(),
  provider_name => 'Xkcd',
  provider_url  => 'http://xkcd.com',
  thumbnail_url => 'https://imgs.xkcd.com/comics/',
  title         => 'Standards',
  type          => 'photo',
  url           => '//imgs.xkcd.com/comics/standards.png',
  version       => '1.0',
  width         => 0,
  },
  'json for xkcd.com'
  or note $link->_dump;

done_testing;

sub photo_html {
  return <<'HERE';
<div class="le-photo le-provider-xkcd">
  <img src="//imgs.xkcd.com/comics/standards.png" alt="Standards">
</div>
HERE
}
