use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://www.greatcirclemapper.net/en/great-circle-mapper.html?route=KJFK-VHHH&aircraft=&speed=' => {
    isa           => 'LinkEmbedder::Link::Basic',
    class         => 'le-rich le-card le-image-card le-provider-greatcirclemapper',
    provider_name => 'Greatcirclemapper',
    html          => qr{<h3>Great Circle Mapper},
  }
);

done_testing;
