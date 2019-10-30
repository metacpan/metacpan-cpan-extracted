use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my $embedder = LinkEmbedder->new;

my $link;
$embedder->get_p('https://bitbucket.org/snippets/bpmedley/895ne')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Basic');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => re(qr{<pre>use Mojolicious::Lite;}),
    provider_name => 'Bitbucket',
    provider_url  => 'https://bitbucket.org/',
    title         => re(qr{ Bitbucket$}),
    thumbnail_url => re(qr{apple-touch-icon}),
    type          => 'rich',
    url           => 'https://bitbucket.org/snippets/bpmedley/895ne',
    version       => '1.0',
  },
  'https://ssl.thorsen.pm/paste/643f88eb788d'
) or note $link->_dump;

done_testing;
