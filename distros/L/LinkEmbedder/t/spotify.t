use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('spotify:track:5tv77MoS0TzE0sJ7RwTj34')->then(sub { $link = shift })->wait;
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

$embedder->get_p('http://open.spotify.com/artist/4HV7yKF3SRpY6I0gxu7hm9')->then(sub { $link = shift })->wait;
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
