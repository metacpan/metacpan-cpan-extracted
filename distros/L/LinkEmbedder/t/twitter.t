use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my %expected = (
  cache_age     => '3153600000',
  provider_name => 'Twitter',
  provider_url  => 'https://twitter.com',
  type          => 'rich',
  version       => '1.0',
);

my $embedder = LinkEmbedder->new;
my $link;

$embedder->get_p('https://twitter.com/jhthorsen')->then(sub { $link = shift })->wait;
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    cache_age     => 0,
    author_name   => re(qr{Jan Henning Thorsen}),
    author_url    => 'https://twitter.com/jhthorsen',
    html          => re(qr{<h3>Jan Henning Thorsen}),
    thumbnail_url => re(qr{twimg\.com/profile_images/.*_400x400}),
    title         => re(qr{Jan Henning Thorsen}),
    url           => 'https://twitter.com/jhthorsen',
  },
  'https://twitter.com/jhthorsen',
) or diag $link->_dump;

$embedder->get_p('https://twitter.com/jhthorsen/status/434045220116643843')->then(sub { $link = shift })->wait;
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    author_name   => 'Jan Henning Thorsen',
    author_url    => 'https://twitter.com/jhthorsen',
    html          => re(qr{blockquote.*href="https://twitter.com/jhthorsen/status/434045220116643843"}s),
    thumbnail_url => re(qr{twimg\.com/profile_images/.*_400x400}),
    title         => 'Jan Henning Thorsen on Twitter',
    url           => 'https://twitter.com/jhthorsen/status/434045220116643843',
  },
  'https://twitter.com/jhthorsen/status/434045220116643843',
) or diag $link->_dump;

$embedder->get_p('https://twitter.com/mulligan/status/555050159189413888/')->then(sub { $link = shift })->wait;
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    author_name   => 'Brenden Mulligan',
    author_url    => 'https://twitter.com/mulligan',
    html          => re(qr{blockquote.*href="https://twitter.com/mulligan/status/555050159189413888"}s),
    thumbnail_url => 'https://pbs.twimg.com/media/B7PvLOSCMAEmBKU.jpg:large',
    title         => 'Brenden Mulligan on Twitter',
    url           => 'https://twitter.com/mulligan/status/555050159189413888',
  },
  'https://twitter.com/mulligan/status/555050159189413888/',
) or diag $link->_dump;

$embedder->get_p('https://twitter.com/mulligan/status/555050159189413888/photo/1')->then(sub { $link = shift })->wait;
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    author_name   => 'Brenden Mulligan',
    author_url    => 'https://twitter.com/mulligan',
    html          => re(qr{blockquote.*href="https://twitter.com/mulligan/status/555050159189413888/photo/1"}s),
    thumbnail_url => 'https://pbs.twimg.com/media/B7PvLOSCMAEmBKU.jpg:large',
    title         => 'Brenden Mulligan on Twitter',
    url           => 'https://twitter.com/mulligan/status/555050159189413888/photo/1',
  },
  'https://twitter.com/mulligan/status/555050159189413888/photo/1',
) or diag $link->_dump;

done_testing;
