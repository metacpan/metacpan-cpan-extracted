use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://www.nhl.com/video/edlers-blistering-one-timer/t-277752844/c-69511103' => {
    isa       => 'LinkEmbedder::Link::NHL',
    cache_age => 0,
    height    => 360,
    html =>
      qr{src="https://www\.nhl\.com/video/embed/edlers-blistering-one-timer/t-277752844/c-69511103\?autostart=false"},
    provider_name => 'NHL',
    provider_url  => 'https://www.nhl.com',
    title         => 'NHL Video',
    type          => 'rich',
    url           => 'https://www.nhl.com/video/edlers-blistering-one-timer/t-277752844/c-69511103',
    version       => '1.0',
    width         => 540,
  }
);

LinkEmbedder->new->test_ok(
  'https://www.nhl.com/gamecenter/stl-vs-ott/2019/10/10/2019020051' => {
    isa           => 'LinkEmbedder::Link::NHL',
    cache_age     => 0,
    html          => qr{href="https://www\.nhl\.com/gamecenter/stl-vs-ott/2019/10/10/2019020051"},
    provider_name => 'NHL',
    provider_url  => 'https://www.nhl.com',
    thumbnail_url => qr{/logos/league/1200x630_NHL.com_FB.JPG},
    title         => 'St. Louis Blues - Ottawa Senators - October 10th, 2019',
    type          => 'rich',
    url           => 'https://www.nhl.com/gamecenter/stl-vs-ott/2019/10/10/2019020051',
    version       => '1.0',
  }
);

LinkEmbedder->new->test_ok(
  'https://www.nhl.com/' => {
    isa           => 'LinkEmbedder::Link::NHL',
    cache_age     => 0,
    html          => qr{href="https://www\.nhl\.com/"},
    provider_name => 'NHL',
    provider_url  => 'https://www.nhl.com',
    thumbnail_url => qr{/logos/league/1200x630_NHL.com_FB.JPG},
    title         => 'Official Site of the National Hockey League',
    type          => 'rich',
    url           => 'https://www.nhl.com/',
    version       => '1.0',
  }
);

done_testing;
