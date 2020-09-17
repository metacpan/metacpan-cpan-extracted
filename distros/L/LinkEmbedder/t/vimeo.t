use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://vimeo.com/154038415' => {
    isa           => 'LinkEmbedder::Link::oEmbed',
    author_name   => 'The Mill',
    cache_age     => 0,
    html          => qr{iframe.*src="},
    provider_name => 'Vimeo',
    provider_url  => 'https://vimeo.com/',
    title         => "Behind the Scenes: The Chemical Brothers 'Wide Open'",
    type          => 'video',
    version       => '1.0',
  }
);

done_testing;
