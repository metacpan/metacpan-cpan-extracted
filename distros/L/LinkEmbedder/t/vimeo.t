use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('https://vimeo.com/154038415')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::oEmbed');
cmp_deeply(
  $link->TO_JSON,
  superhashof({
    author_name   => 'The Mill',
    cache_age     => 0,
    html          => re(qr{iframe.*src="}),
    provider_name => 'Vimeo',
    provider_url  => 'https://vimeo.com/',
    title         => "Behind the Scenes: The Chemical Brothers 'Wide Open'",
    type          => 'video',
    version       => '1.0',
  }),
  'https://www.youtube.com/watch?v=OspRE1xnLjE'
) or note $link->_dump;

done_testing;
