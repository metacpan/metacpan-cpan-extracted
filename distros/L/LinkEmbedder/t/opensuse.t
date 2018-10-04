use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my @urls = (
  'http://paste.opensuse.org/2931429',
  'http://paste.opensuse.org/view/raw/2931429',
  'http://paste.opensuse.org/view/simple/2931429',
);

for my $url (@urls) {
  my $link;
  $embedder->get_p($url)->then(sub { $link = shift })->wait;
  isa_ok($link, 'LinkEmbedder::Link::OpenSUSE');
  cmp_deeply(
    $link->TO_JSON,
    {
      cache_age     => 0,
      html          => re(qr{<pre>\$testing = &quot;some stuff&quot;;</pre>}),
      provider_name => 'openSUSE',
      provider_url  => 'http://paste.opensuse.org/',
      title         => 'Paste 2931429',
      type          => 'rich',
      url           => $url,
      version       => '1.0',
    },
    "$url"
  ) or note $link->_dump;
}

done_testing;
