use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my @urls = (
  'https://twitter.com/jhthorsen/status/434045220116643843',
  'https://twitter.com/mulligan/status/555050159189413888/',
  'https://twitter.com/mulligan/status/555050159189413888/photo/1',
);

for my $src_url (@urls) {
  my $url = Mojo::URL->new($src_url);
  $url->path->trailing_slash(0);
  pop @{$url->path} while @{$url->path} > 3;

  my $encoded_url = Mojo::Util::url_escape($url->to_string);
  LinkEmbedder->new->test_ok(
    $src_url => {
      provider_name => 'Twitter',
      provider_url  => 'https://twitter.com',
      type          => 'rich',
      version       => '1.0',
      author_name   => qr{^(jhthorsen|mulligan)$},
      author_url    => qr{^https://twitter.com/(jhthorsen|mulligan)$},
      cache_age     => 0,
      html => qr{<iframe class="le-rich le-provider-twitter" .* src="https://twitframe\.com/show\?url=$encoded_url},
      url  => $url->to_string,
    }
  );
}

done_testing;
