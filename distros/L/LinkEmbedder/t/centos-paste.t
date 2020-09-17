use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_CENTOS_ID=89d81534' unless $ENV{TEST_CENTOS_ID};
plan skip_all => 'cpanm IO::Socket::SSL'   unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  "https://paste.centos.org/view/$ENV{TEST_CENTOS_ID}" => {
    cache_age     => 0,
    html          => qr{<pre>sub foo},
    isa           => 'LinkEmbedder::Link::Basic',
    provider_name => 'Centos',
    provider_url  => 'https://paste.centos.org/',
    title         => qr{- Pastebin Service},
    type          => 'rich',
    url           => "https://paste.centos.org/view/$ENV{TEST_CENTOS_ID}",
    version       => '1.0',
  }
);

done_testing;
