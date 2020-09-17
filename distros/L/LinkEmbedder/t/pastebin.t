use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://pastebin.com/V5gZTzhy' => {
    isa           => 'LinkEmbedder::Link::Pastebin',
    cache_age     => 0,
    html          => qr{<pre>x=\$\(too cool\);</pre>},
    provider_name => 'Pastebin',
    provider_url  => 'https://pastebin.com',
    thumbnail_url => 'https://pastebin.com/i/facebook.png',
    title         => 'too cool paste - Pastebin.com',
    type          => 'rich',
    url           => 'https://pastebin.com/V5gZTzhy',
    version       => '1.0',
  }
);

done_testing;
