use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my $link;
$embedder->get_p('https://perlbot.pl/p/mgyz68')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Basic');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => re(qr{<pre>my \$link;}),
    provider_name => 'Perlbot',
    provider_url  => 'https://perlbot.pl/',
    title         => re(qr{Perlbot Pastebin}),
    type          => 'rich',
    url           => 'https://perlbot.pl/p/mgyz68',
    version       => '1.0',
  },
  'https://perlbot.pl'
) or note $link->_dump;

done_testing;
