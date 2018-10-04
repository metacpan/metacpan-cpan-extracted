use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('https://travis-ci.org/Nordaaker/convos/builds/47421379')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Travis');
is_deeply $link->TO_JSON,
  {
  cache_age        => 0,
  html             => html(),
  provider_name    => 'Travis',
  provider_url     => 'https://travis-ci.org',
  thumbnail_height => 501,
  thumbnail_url    => 'https://cdn.travis-ci.org/images/logos/TravisCI-Mascot-1-20feeadb48fc2492ba741d89cb5a5c8a.png',
  thumbnail_width  => 497,
  title            => 'Build succeeded at 2015-01-18T13:30:57Z',
  type             => 'rich',
  url              => 'https://travis-ci.org/Nordaaker/convos/builds/47421379',
  version          => '1.0',
  },
  'json'
  or note $link->_dump;

done_testing;

sub html {
  return <<'HERE';
<div class="le-card le-image-card le-rich le-provider-travis">
    <a href="https://travis-ci.org/Nordaaker/convos/builds/47421379" class="le-thumbnail">
      <img src="https://cdn.travis-ci.org/images/logos/TravisCI-Mascot-1-20feeadb48fc2492ba741d89cb5a5c8a.png" alt="Placeholder">
    </a>
  <h3>Build succeeded at 2015-01-18T13:30:57Z</h3>
  <p class="le-description">Jan Henning Thorsen: cpanm --from https://cpan.metacpan.org/</p>
  <div class="le-meta">
    <span class="le-goto-link"><a href="https://travis-ci.org/Nordaaker/convos/builds/47421379"><span>https://travis-ci.org/Nordaaker/convos/builds/47421379</span></a></span>
  </div>
</div>
HERE
}
