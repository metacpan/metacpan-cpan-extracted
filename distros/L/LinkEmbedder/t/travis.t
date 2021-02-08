use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://travis-ci.org/Nordaaker/convos/builds/47421379' => {
    isa              => 'LinkEmbedder::Link::Travis',
    cache_age        => 0,
    class            => 'le-rich le-card le-image-card le-provider-travis',
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
  }
);

done_testing;

sub html {
  return <<'HERE';
<div class="le-rich le-card le-image-card le-provider-travis">
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
