use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my $embedder = LinkEmbedder->new(force_secure => 1);
my $link;
$embedder->get_p('http://imgur.com/w3cmS')->then(sub { $link = shift })->wait;    # exists since Jan 2, 2011
isa_ok($link, 'LinkEmbedder::Link::Imgur');
is_deeply $link->TO_JSON,
  {
  cache_age        => 0,
  height           => 0,
  html             => photo_html(),
  provider_name    => 'Imgur',
  provider_url     => 'https://imgur.com',
  thumbnail_height => 315,
  thumbnail_url    => 'https://i.imgur.com/w3cmS.png?fb',
  thumbnail_width  => 600,
  title            => 'Attempt to sit still until cat decides to move.  via  #reddit',
  type             => 'photo',
  url              => 'https://i.imgur.com/w3cmS.png',
  version          => '1.0',
  width            => 0,
  },
  'json for imgur.com'
  or note $link->_dump;

note 'Make sure that force_secure=1 works';
$embedder->get_p('http://imgur.com/w3cmS.png')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Imgur');
my $html = photo_html();
$html =~ s!alt="[^"]+"!alt="w3cmS.png"!;
$html =~ s!i\.imgur\.com!imgur.com!;
is_deeply $link->TO_JSON,
  {
  cache_age     => 0,
  height        => 0,
  html          => $html,
  provider_name => 'Imgur',
  provider_url  => 'https://imgur.com',
  title         => 'w3cmS.png',
  type          => 'photo',
  url           => 'https://imgur.com/w3cmS.png',
  version       => '1.0',
  width         => 0,
  },
  'json for imgur.com png image'
  or note $link->_dump;

done_testing;

sub photo_html {
  return <<'HERE';
<div class="le-photo le-provider-imgur">
  <img src="https://i.imgur.com/w3cmS.png" alt="Attempt to sit still until cat decides to move.  via  #reddit">
</div>
HERE
}
