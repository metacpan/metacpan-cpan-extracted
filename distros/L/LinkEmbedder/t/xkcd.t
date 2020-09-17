use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://xkcd.com/927' => {
    isa           => 'LinkEmbedder::Link::Xkcd',
    cache_age     => 0,
    height        => 0,
    html          => photo_html(),
    provider_name => 'Xkcd',
    provider_url  => 'https://xkcd.com',
    thumbnail_url => '//imgs.xkcd.com/comics/standards.png',
    title         => 'Standards',
    type          => 'photo',
    url           => 'https://xkcd.com/927',
    version       => '1.0',
    width         => 0,
  }
);

done_testing;

sub photo_html {
  return <<'HERE';
<div class="le-photo le-provider-xkcd">
  <img src="//imgs.xkcd.com/comics/standards.png" alt="Standards">
</div>
HERE
}
