use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'spotify:track:5tv77MoS0TzE0sJ7RwTj34' => {
    isa       => 'LinkEmbedder::Link::Spotify',
    cache_age => 0,
    html =>
      qr{<iframe.*src="https://embed\.spotify\.com\?theme=white&amp;uri=spotify%3Atrack%3A5tv77MoS0TzE0sJ7RwTj34&amp;view="},
    provider_name => 'Spotify',
    provider_url  => 'https://spotify.com',
    type          => 'rich',
    url           => 'spotify:track:5tv77MoS0TzE0sJ7RwTj34',
    version       => '1.0',
  }
);

LinkEmbedder->new->test_ok(
  'https://open.spotify.com/artist/4HV7yKF3SRpY6I0gxu7hm9' => {
    isa       => 'LinkEmbedder::Link::Spotify',
    cache_age => 0,
    html =>
      qr{<iframe.*src="https://embed\.spotify\.com\?theme=white&amp;uri=spotify%3Aartist%3A4HV7yKF3SRpY6I0gxu7hm9&amp;view="},
    provider_name => 'Spotify',
    provider_url  => 'https://spotify.com',
    type          => 'rich',
    url           => 'https://open.spotify.com/artist/4HV7yKF3SRpY6I0gxu7hm9',
    version       => '1.0',
  }
);

done_testing;
