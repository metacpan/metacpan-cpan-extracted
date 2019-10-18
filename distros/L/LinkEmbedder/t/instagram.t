use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('https://www.instagram.com/p/C/')->then(sub { $link = shift })->wait; # oldest IG post
isa_ok($link, 'LinkEmbedder::Link::oEmbed');

my $json = $link->TO_JSON;

like delete($json->{html}), qr{instagram-media}, 'html';
like delete($json->{thumbnail_url}), qr{/11142282_807944772625369_492138085_n\.jpg}, 'thumbnail_url';

is_deeply $json,
  {
  author_name      => 'kevin',
  author_url       => 'https://www.instagram.com/kevin',
  cache_age        => 0,
  provider_name    => 'Instagram',
  provider_url     => 'https://www.instagram.com',
  thumbnail_height => '612',
  thumbnail_width  => '612',
  title            => "test",
  type             => 'rich',
  url              => 'https://www.instagram.com/p/C/',
  version          => '1.0',
  width            => '658',
  },
  'json'
  or note $link->_dump;

done_testing;
