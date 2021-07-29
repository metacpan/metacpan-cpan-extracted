use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://travis-ci.org/Nordaaker/convos/builds/47421379' => {
    isa              => 'LinkEmbedder::Link::Travis',
    cache_age        => 0,
    class            => 'le-rich le-card le-image-card le-provider-travis',
    html             => qr{Build has},
    provider_name    => 'Travis',
    provider_url     => 'https://travis-ci.org',
    thumbnail_height => 501,
    thumbnail_url    => 'https://cdn.travis-ci.org/images/logos/TravisCI-Mascot-1-20feeadb48fc2492ba741d89cb5a5c8a.png',
    thumbnail_width  => 497,
    title            => qr{Build has},
    type             => 'rich',
    url              => 'https://travis-ci.org/Nordaaker/convos/builds/47421379',
    version          => '1.0',
  }
);

done_testing;
