use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

my $embedder = LinkEmbedder->new;
my $link     = $embedder->get('spotify:track:5tv77MoS0TzE0sJ7RwTj34');
isa_ok($link, 'LinkEmbedder::Link::Spotify');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age => 0,
    html      => re(
      qr{<iframe.*src="https://embed\.spotify\.com\?theme=white&amp;uri=spotify%3Atrack%3A5tv77MoS0TzE0sJ7RwTj34&amp;view="}
    ),
    provider_name => 'Spotify',
    provider_url  => 'https://spotify.com',
    type          => 'rich',
    url           => 'spotify:track:5tv77MoS0TzE0sJ7RwTj34',
    version       => '1.0',
  },
  'spotify:track:5tv77MoS0TzE0sJ7RwTj34'
) or note $link->_dump;

$link = $embedder->get('http://open.spotify.com/artist/4HV7yKF3SRpY6I0gxu7hm9');
isa_ok($link, 'LinkEmbedder::Link::Spotify');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age => 0,
    html      => re(
      qr{<iframe.*src="https://embed\.spotify\.com\?theme=white&amp;uri=spotify%3Aartist%3A4HV7yKF3SRpY6I0gxu7hm9&amp;view="}
    ),
    provider_name => 'Spotify',
    provider_url  => 'https://spotify.com',
    type          => 'rich',
    url           => 'http://open.spotify.com/artist/4HV7yKF3SRpY6I0gxu7hm9',
    version       => '1.0',
  },
  'spotify:track:5tv77MoS0TzE0sJ7RwTj34'
) or note $link->_dump;


done_testing;
