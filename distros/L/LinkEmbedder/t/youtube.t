use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('https://www.youtube.com/watch?v=OspRE1xnLjE')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::oEmbed');
cmp_deeply(
  $link->TO_JSON,
  superhashof({
    author_name   => re(qr{Mojoconf}),
    author_url    => 'https://www.youtube.com/channel/UCgk2wCZr5Rk-cewLTtQA_Fg',
    cache_age     => 0,
    html          => re(qr{iframe.*src="}),
    provider_name => 'YouTube',
    provider_url  => 'https://www.youtube.com/',
    title         => "Mojoconf 2014 - Sebastian Riedel - What's new in Mojolicious 5.0",
    type          => 'video',
    url           => 'https://www.youtube.com/watch?v=OspRE1xnLjE',
    version       => '1.0',
  }),
  'https://www.youtube.com/watch?v=OspRE1xnLjE'
) or note $link->_dump;

done_testing;
