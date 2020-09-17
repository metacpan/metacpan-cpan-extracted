use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://www.ted.com/talks/jill_bolte_taylor_s_powerful_stroke_of_insight' => {
    isa           => 'LinkEmbedder::Link::oEmbed',
    author_name   => 'Jill Bolte Taylor',
    cache_age     => 300,
    html          => qr{iframe.*src="},
    provider_name => 'TED',
    provider_url  => 'https://www.ted.com',
    title         => "Jill Bolte Taylor: My stroke of insight",
    type          => 'video',
    version       => '1.0',
  }
);

done_testing;
