use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('https://www.instagram.com/p/BQzeGY0gd63')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::oEmbed');

my $json = $link->TO_JSON;

like delete($json->{html}), qr{instagram-media}, 'html';
like delete($json->{thumbnail_url}), qr{/16585734_1256460307782370_723156494169669632_n\.jpg}, 'thumbnail_url';

is_deeply $json,
  {
  author_name      => 'thuygia',
  author_url       => 'https://www.instagram.com/thuygia',
  cache_age        => 0,
  provider_name    => 'Instagram',
  provider_url     => 'https://www.instagram.com',
  thumbnail_height => '640',
  thumbnail_width  => '640',
  title            => "\x{2764}Designing products people love by \@scotthurff",
  type             => 'rich',
  url              => 'https://www.instagram.com/p/BQzeGY0gd63',
  version          => '1.0',
  width            => '658',
  },
  'json'
  or note $link->_dump;

done_testing;
