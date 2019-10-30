use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;
plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my $link;
$embedder->get_p('https://whereby.com/your-room-name')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::AppearIn');
cmp_deeply $link->TO_JSON,
  {
  cache_age     => 0,
  height        => 390,
  html          => re(qr{src="https://whereby\.com/your-room-name"}),
  provider_name => 'AppearIn',
  provider_url  => 'https://whereby.com',
  title         => 'Join the room your-room-name',
  type          => 'rich',
  url           => 'https://whereby.com/your-room-name',
  version       => '1.0',
  width         => 740,
  },
  'https://whereby.com/your-room-name'
  or note $link->_dump;

done_testing;
