use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my @urls = (
  'https://paste.opensuse.org/2931429',
  'https://paste.opensuse.org/view/raw/2931429',
  'https://paste.opensuse.org/view/simple/2931429',
);

for my $url (@urls) {
  LinkEmbedder->new->test_ok(
    $url => {
      isa           => 'LinkEmbedder::Link::OpenSUSE',
      cache_age     => 0,
      html          => qr{<pre>\$testing = &quot;some stuff&quot;;</pre>},
      provider_name => 'openSUSE',
      provider_url  => 'https://paste.opensuse.org/',
      title         => 'Paste 2931429',
      type          => 'rich',
      url           => $url,
      version       => '1.0',
    }
  );
}

done_testing;
