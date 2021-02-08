use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;
plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};

LinkEmbedder->new->test_ok(
  'https://meet.google.com/cqd-myxw-phs' => {
    cache_age     => 0,
    class         => 'le-rich le-video-chat le-provider-google',
    html          => qr{src="https://meet\.google\.com/cqd-myxw-phs"},
    isa           => 'LinkEmbedder::Link::Google',
    provider_name => 'Google',
    provider_url  => 'https://meet.google.com/',
    title         => 'Join the room cqd-myxw-phs',
    type          => 'rich',
    url           => 'https://meet.google.com/cqd-myxw-phs',
    version       => '1.0',
  }
);

done_testing;
