use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;
plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};

$ENV{TEST_JITSI_URL} ||= 'https://meet.jit.si/convostest';
my $provider_url = Mojo::URL->new($ENV{TEST_JITSI_URL})->path('')->to_string;

LinkEmbedder->new->test_ok(
  $ENV{TEST_JITSI_URL} => {
    html          => qr{allow="camera;microphone".*src="$provider_url[^"]+"},
    isa           => 'LinkEmbedder::Link::Jitsi',
    provider_name => 'Jitsi',
    provider_url  => $provider_url,
    title         => 'Join the room convostest',
    type          => 'rich',
    url           => $ENV{TEST_JITSI_URL},
    version       => '1.0',
  }
);

LinkEmbedder->new->test_ok(
  $provider_url => {
    html          => qr{le-provider-jitsi.*<a href}s,
    isa           => 'LinkEmbedder::Link::Jitsi',
    provider_name => 'Jitsi',
    provider_url  => $provider_url,
    title         => 'Jitsi Meet',
    type          => 'rich',
    url           => $provider_url,
    version       => '1.0',
  }
);

done_testing;
