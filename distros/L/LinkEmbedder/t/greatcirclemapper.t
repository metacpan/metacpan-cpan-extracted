use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://www.greatcirclemapper.net/en/great-circle-mapper.html?route=KJFK-VHHH&aircraft=&speed=' => {
    isa           => 'LinkEmbedder::Link::Basic',
    provider_name => 'Greatcirclemapper',
    html          => qr{class="le-card le-image-card le-rich le-provider-greatcirclemapper"},
  }
);

done_testing;
