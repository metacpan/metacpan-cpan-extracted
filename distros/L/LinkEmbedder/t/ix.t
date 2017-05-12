use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my $link = $embedder->get('http://ix.io/fpW');
isa_ok($link, 'LinkEmbedder::Link::Ix');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => paste_html(),
    provider_name => 'Ix',
    provider_url  => 'http://ix.io',
    type          => 'rich',
    url           => 'http://ix.io/fpW',
    version       => '1.0',
  },
  'http://ix.io/fpW',
) or note $link->_dump;

done_testing;

sub paste_html {
  return <<"HERE";
<div class="le-paste le-provider-ix le-rich">
  <div class="le-meta">
    <span class="le-provider-link"><a href="http://ix.io">Ix</a></span>
    <span class="le-goto-link"><a href="http://ix.io/fpW" title="">View</a></span>
  </div>
  <pre>Hello world.</pre>
</div>
HERE
}
