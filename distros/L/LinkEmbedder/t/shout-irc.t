use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my $link = $embedder->get('http://demo.shout-irc.com/');
isa_ok($link, 'LinkEmbedder::Link::Basic');
is_deeply $link->TO_JSON, {
  cache_age => 0,
  html      => <<'HERE',
<div class="le-card le-image-card le-rich le-provider-shout-irc">
    <a href="http://demo.shout-irc.com/" class="le-thumbnail">
      <img src="http://demo.shout-irc.com/img/apple-touch-icon-120x120.png" alt="Placeholder">
    </a>
  <h3>Shout</h3>
  <p class="le-description">You&#39;re currently running version 0.52.0 Check for updates</p>
  <div class="le-meta">
    <span class="le-goto-link"><a href="http://demo.shout-irc.com/"><span>http://demo.shout-irc.com/</span></a></span>
  </div>
</div>
HERE
  provider_name => 'Shout-irc',
  provider_url  => 'http://demo.shout-irc.com/',
  thumbnail_url => 'http://demo.shout-irc.com/img/apple-touch-icon-120x120.png',
  title         => 'Shout',
  type          => 'rich',
  url           => 'http://demo.shout-irc.com/',
  version       => '1.0',
  },
  'json for shout-irc';

# http://demo.shout-irc.com/
# <link rel="icon" sizes="192x192" href="/img/touch-icon-192x192.png">
# <p class="about">

done_testing;
