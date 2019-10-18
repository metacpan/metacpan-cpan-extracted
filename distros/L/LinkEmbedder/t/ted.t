use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('https://www.ted.com/talks/jill_bolte_taylor_s_powerful_stroke_of_insight')
  ->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::oEmbed');
cmp_deeply(
  $link->TO_JSON,
  superhashof({
    author_name   => 'Jill Bolte Taylor',
    cache_age     => 300,
    html          => re(qr{iframe.*src="}),
    provider_name => 'TED',
    provider_url  => 'https://www.ted.com',
    title         => "Jill Bolte Taylor: My stroke of insight",
    type          => 'video',
    version       => '1.0',
  }),
  'https://www.ted.com/talks/jill_bolte_taylor_s_powerful_stroke_of_insight'
) or note $link->_dump;

done_testing;
