use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new(force_secure => 1);
$embedder->test_ok(
  'http://imgur.com/w3cmS' => {
    isa           => 'LinkEmbedder::Link::Imgur',
    cache_age     => 0,
    height        => 0,
    html          => photo_html(),
    provider_name => 'Imgur',
    provider_url  => 'https://imgur.com',
    thumbnail_url => 'https://i.imgur.com/w3cmSl.png',
    title         => 'Attempt to sit still until cat decides to move.  via  #reddit',
    type          => 'photo',
    url           => 'https://imgur.com/w3cmS',
    version       => '1.0',
    width         => 0,
  }
);

my $html = photo_html();
$html =~ s!alt="[^"]+"!alt="w3cmSl.png"!;
$html =~ s!i\.imgur\.com!imgur.com!;
$embedder->test_ok(
  'http://imgur.com/w3cmSl.png' => {
    isa           => 'LinkEmbedder::Link::Imgur',
    html          => $html,
    cache_age     => 0,
    height        => 0,
    html          => $html,
    provider_name => 'Imgur',
    provider_url  => 'https://imgur.com',
    title         => 'w3cmSl.png',
    type          => 'photo',
    url           => 'https://imgur.com/w3cmSl.png',
    version       => '1.0',
    width         => 0,
  }
);

done_testing;

sub photo_html {
  return <<'HERE';
<div class="le-photo le-provider-imgur">
  <img src="https://i.imgur.com/w3cmSl.png" alt="Attempt to sit still until cat decides to move.  via  #reddit">
</div>
HERE
}
