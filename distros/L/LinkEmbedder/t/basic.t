use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://www.fortunecowsay.com/' => {
    isa  => 'LinkEmbedder::Link::Basic',
    html => qr{div class="le-paste le-provider-fortunecowsay le-rich".*pre.*\|\|-+w\s*\|}s,
  }
);

LinkEmbedder->new->test_ok(
  'https://catoverflow.com/cats/r4cIt4z.gif' => {
    isa           => 'LinkEmbedder::Link::Basic',
    cache_age     => 0,
    height        => 0,
    html          => catoverflow_html(),
    provider_name => 'Catoverflow',
    provider_url  => 'https://catoverflow.com/',
    title         => 'r4cIt4z.gif',
    type          => 'photo',
    url           => 'https://catoverflow.com/cats/r4cIt4z.gif',
    version       => '1.0',
    width         => 0,
  }
);

LinkEmbedder->new->test_ok(
  'https://thorsen.pm/blog/' => {
    cache_age     => 0,
    html          => thorsen_html(),
    provider_name => 'Thorsen',
    title         => 'My blog - thorsen.pm',
    type          => 'rich',
    url           => 'https://thorsen.pm/blog/',
    provider_url  => 'https://thorsen.pm/',
    thumbnail_url => 'https://www.thorsen.pm/editor/wp-content/uploads/2019/03/jhthorsen-face-1300.jpg',
    version       => '1.0'
  }
);

LinkEmbedder->new->test_ok(
  'https://www.aftenposten.no/kultur/i/lo5X7/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker' => {
    isa              => 'LinkEmbedder::Link::Basic',
    author_name      => qr{Per Kristian},
    cache_age        => 0,
    html             => qr{class="le-card le-image-card le-rich le-provider-aftenposten".*Google har}s,
    provider_name    => 'Aftenposten',
    provider_url     => 'https://www.aftenposten.no/',
    thumbnail_height => 1047,
    thumbnail_url    => qr{https:},
    thumbnail_width  => 2000,
    title            => 'Google har skapt kunstig intelligens som trener seg selv',
    type             => 'rich',
    url     => 'https://www.aftenposten.no/kultur/i/lo5X7/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker',
    version => '1.0'
  }
);

done_testing;

sub catoverflow_html {
  return <<'HERE';
<div class="le-photo le-provider-catoverflow">
  <img src="https://catoverflow.com/cats/r4cIt4z.gif" alt="r4cIt4z.gif">
</div>
HERE
}

sub thorsen_html {
  return <<'HERE';
<div class="le-card le-image-card le-rich le-provider-thorsen">
    <a href="https://thorsen.pm/blog/" class="le-thumbnail">
      <img src="https://www.thorsen.pm/editor/wp-content/uploads/2019/03/jhthorsen-face-1300.jpg" alt="Placeholder">
    </a>
  <h3>My blog - thorsen.pm</h3>
  <p class="le-description">All blog posts written by Jan Henning Thorsen.</p>
  <div class="le-meta">
    <span class="le-goto-link"><a href="https://thorsen.pm/blog/"><span>https://thorsen.pm/blog/</span></a></span>
  </div>
</div>
HERE
}
