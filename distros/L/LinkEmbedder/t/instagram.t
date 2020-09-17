use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://www.instagram.com/p/C/' => {
    isa              => 'LinkEmbedder::Link::Instagram',
    html             => qr{<iframe class="le-rich le-provider-instagram".*src="https://www\.instagram\.com/p/C/embed"},
    thumbnail_url    => qr{/11142282_807944772625369_492138085_n\.jpg},
    author_name      => 'kevin',
    author_url       => 'https://www.instagram.com/kevin',
    cache_age        => 0,
    provider_name    => 'Instagram',
    provider_url     => 'https://www.instagram.com',
    thumbnail_height => '480',
    thumbnail_width  => '480',
    title            => "test",
    type             => 'rich',
    url              => 'https://www.instagram.com/p/C/',
    version          => '1.0',
    width            => '658',
  }
);

LinkEmbedder->new->test_ok(
  'https://www.instagram.com/p/CFOCg0shCqz/' => {
    isa  => 'LinkEmbedder::Link::Instagram',
    html => qr{<iframe class="le-rich le-provider-instagram".*src="https://www\.instagram\.com/p/CFOCg0shCqz/embed"},
    thumbnail_url    => qr{/119498171_1255132661505212_1788503835285257132_n.jpg},
    author_name      => 'fuglenasakusa',
    author_url       => 'https://www.instagram.com/fuglenasakusa',
    cache_age        => 0,
    provider_name    => 'Instagram',
    provider_url     => 'https://www.instagram.com',
    thumbnail_height => '640',
    thumbnail_width  => '640',
    title            => qr{Fuglen},
    type             => 'rich',
    url              => 'https://www.instagram.com/p/CFOCg0shCqz/',
    version          => '1.0',
    width            => '658',
  }
);

done_testing;
