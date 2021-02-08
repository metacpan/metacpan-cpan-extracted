use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;
plan skip_all => 'TEST_WEBEX_URL='       unless $ENV{TEST_WEBEX_URL};

LinkEmbedder->new->test_ok(
  $ENV{TEST_WEBEX_URL} => {
    cache_age     => 0,
    class         => 'le-rich le-video-chat le-provider-webex',
    html          => qr{src="$ENV{TEST_WEBEX_URL}"},
    isa           => 'LinkEmbedder::Link::Webex',
    provider_name => 'Webex',
    provider_url  => 'https://webex.com',
    title         => qr{Join the room},
    type          => 'rich',
    url           => $ENV{TEST_WEBEX_URL},
    version       => '1.0',
  }
);

done_testing;
