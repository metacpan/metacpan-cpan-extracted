use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://p.thorsen.pm/3808406ec6f6' => {
    cache_age     => 0,
    html          => qr{<pre>&lt;test&gt;paste!&lt;/test&gt;</pre>},
    isa           => 'LinkEmbedder::Link::Basic',
    provider_name => 'Thorsen',
    provider_url  => 'https://p.thorsen.pm/',
    title         => qr{ - Mojopaste},
    type          => 'rich',
    url           => 'https://p.thorsen.pm/3808406ec6f6',
    version       => '1.0',
  }
);

done_testing;
