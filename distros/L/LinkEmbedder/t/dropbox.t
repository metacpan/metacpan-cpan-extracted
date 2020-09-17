use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

LinkEmbedder->new->test_ok(
  'https://www.dropbox.com/s/nhjyi76so7b93lv/IMG_2394.jpg?dl=0' => {
    cache_age        => 0,
    html             => qr{<img src="},
    isa              => 'LinkEmbedder::Link::Dropbox',
    provider_name    => 'Dropbox',
    provider_url     => 'https://dropbox.com',
    thumbnail_height => 160,
    thumbnail_url    => qr{https://www\.dropbox\.com.*size=},
    thumbnail_width  => 160,
    title            => 'IMG_2394.jpg',
    type             => 'rich',
    url              => 'https://www.dropbox.com/s/nhjyi76so7b93lv/IMG_2394.jpg?dl=0',
    version          => '1.0',
  }
);

done_testing;
