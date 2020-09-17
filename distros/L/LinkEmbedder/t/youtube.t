use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://www.youtube.com/watch?v=OspRE1xnLjE' => {
    isa           => 'LinkEmbedder::Link::oEmbed',
    author_name   => qr{Mojoconf},
    author_url    => 'https://www.youtube.com/channel/UCgk2wCZr5Rk-cewLTtQA_Fg',
    cache_age     => 0,
    html          => qr{iframe.*src="},
    provider_name => 'YouTube',
    provider_url  => 'https://www.youtube.com/',
    title         => "Mojoconf 2014 - Sebastian Riedel - What's new in Mojolicious 5.0",
    type          => 'video',
    url           => 'https://www.youtube.com/watch?v=OspRE1xnLjE',
    version       => '1.0',
  }
);

done_testing;
