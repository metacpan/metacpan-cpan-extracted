use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://bitbucket.org/snippets/bpmedley/895ne' => {
    cache_age     => 0,
    html          => qr{<pre>use Mojolicious::Lite;},
    isa           => 'LinkEmbedder::Link::Basic',
    provider_name => 'Bitbucket',
    provider_url  => 'https://bitbucket.org/',
    title         => qr{ Bitbucket$},
    thumbnail_url => qr{apple-touch-icon},
    type          => 'rich',
    url           => 'https://bitbucket.org/snippets/bpmedley/895ne',
    version       => '1.0',
  }
);

done_testing;
