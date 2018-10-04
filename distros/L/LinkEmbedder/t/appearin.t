use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('https://appear.in/your-room-name')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::AppearIn');
cmp_deeply $link->TO_JSON,
  {
  cache_age     => 0,
  height        => 390,
  html          => re(qr{src="https://appear\.in/your-room-name"}),
  provider_name => 'AppearIn',
  provider_url  => 'https://appear.in',
  title         => 'Join the room your-room-name',
  type          => 'rich',
  url           => 'https://appear.in/your-room-name',
  version       => '1.0',
  width         => 740,
  },
  'https://appear.in/your-room-name'
  or note $link->_dump;

done_testing;
