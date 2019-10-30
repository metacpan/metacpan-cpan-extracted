use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my $embedder = LinkEmbedder->new;

# video embed
my $video_link;
$embedder->get_p('https://www.nhl.com/video/edlers-blistering-one-timer/t-277752844/c-69511103')
  ->then(sub { $video_link = shift })->wait;
isa_ok($video_link, 'LinkEmbedder::Link::NHL');
cmp_deeply $video_link->TO_JSON,
  {
  cache_age => 0,
  height    => 360,
  html =>
    re(qr{src="https://www\.nhl\.com/video/embed/edlers-blistering-one-timer/t-277752844/c-69511103\?autostart=false"}),
  provider_name => 'NHL',
  provider_url  => 'https://www.nhl.com',
  title         => 'NHL Video',
  type          => 'rich',
  url           => 'https://www.nhl.com/video/edlers-blistering-one-timer/t-277752844/c-69511103',
  version       => '1.0',
  width         => 540,
  },
  'https://www.nhl.com/video/edlers-blistering-one-timer/t-277752844/c-69511103'
  or note $video_link->_dump;

# an article
my $article_link;
$embedder->get_p('https://www.nhl.com/gamecenter/stl-vs-ott/2019/10/10/2019020051')
  ->then(sub { $article_link = shift })->wait;
isa_ok($article_link, 'LinkEmbedder::Link::NHL');
cmp_deeply $article_link->TO_JSON,
  {
  cache_age     => 0,
  html          => re(qr{href="https://www\.nhl\.com/gamecenter/stl-vs-ott/2019/10/10/2019020051"}),
  provider_name => 'NHL',
  provider_url  => 'https://www.nhl.com',
  thumbnail_url => 'https://nhl.bamcontent.com/images/logos/league/1200x630_NHL.com_FB.JPG',
  title         => 'St. Louis Blues - Ottawa Senators - October 10th, 2019',
  type          => 'rich',
  url           => 'https://www.nhl.com/gamecenter/stl-vs-ott/2019/10/10/2019020051',
  version       => '1.0',
  },
  'https://www.nhl.com/video/edlers-blistering-one-timer/t-277752844/c-69511103'
  or note $article_link->_dump;

# home page
my $homepage_link;
$embedder->get_p('https://www.nhl.com/')->then(sub { $homepage_link = shift })->wait;
isa_ok($homepage_link, 'LinkEmbedder::Link::NHL');
cmp_deeply $homepage_link->TO_JSON,
  {
  cache_age     => 0,
  html          => re(qr{href="https://www\.nhl\.com/"}),
  provider_name => 'NHL',
  provider_url  => 'https://www.nhl.com',
  thumbnail_url => 'https://nhl.bamcontent.com/images/logos/league/1200x630_NHL.com_FB.JPG',
  title         => 'Official Site of the National Hockey League',
  type          => 'rich',
  url           => 'https://www.nhl.com/',
  version       => '1.0',
  },
  'https://www.nhl.com/'
  or note $homepage_link->_dump;

done_testing;
