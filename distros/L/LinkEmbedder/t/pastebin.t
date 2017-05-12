use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my $link = $embedder->get('https://pastebin.com/V5gZTzhy');
isa_ok($link, 'LinkEmbedder::Link::Pastebin');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => re(qr{<pre>x=\$\(too cool\);</pre>}),
    provider_name => 'Pastebin',
    provider_url  => 'https://pastebin.com',
    thumbnail_url => 'https://pastebin.com/i/facebook.png',
    title         => '[Bash] too cool paste - Pastebin.com',
    type          => 'rich',
    url           => 'https://pastebin.com/V5gZTzhy',
    version       => '1.0',
  },
  'https://pastebin.com/V5gZTzhy',
) or note $link->_dump;

done_testing;
