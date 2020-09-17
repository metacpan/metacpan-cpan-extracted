use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'http://ix.io/fpW' => {
    isa           => 'LinkEmbedder::Link::Ix',
    cache_age     => 0,
    html          => paste_html(),
    provider_name => 'Ix',
    provider_url  => 'http://ix.io',
    type          => 'rich',
    url           => 'http://ix.io/fpW',
    version       => '1.0',
  }
);

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
