use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my %expected = (
  cache_age     => '0',
  provider_name => 'GitHub',
  provider_url  => 'https://github.com',
  type          => 'rich',
  version       => '1.0',
);

LinkEmbedder->new->test_ok(
  'https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl' => {
    %expected,
    isa           => 'LinkEmbedder::Link::Github',
    html          => qr{use LinkEmbedder;.*decodeURIComponent}s,
    thumbnail_url => qr{githubusercontent\.com/},
    title         => qr{linkembedder/embedder.pl},
    url           => 'https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl',
  }
);

LinkEmbedder->new->test_ok(
  'https://git.io/aKhMuA' => {
    isa => 'LinkEmbedder::Link::Github',
    %expected,
    html          => qr{simplest way.*IRC},
    thumbnail_url => qr{githubusercontent\.com/},
    title         => "Add back compat redirect from /convos to / \x{b7} Nordaaker/convos\@668368b",
    url           => "https://git.io/aKhMuA",
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/jhthorsen' => {
    %expected,
    isa           => 'LinkEmbedder::Link::Github',
    html          => qr{Follow their code on GitHub},
    thumbnail_url => qr{githubusercontent.com/u/45729\b},
    title         => "jhthorsen (Jan Henning Thorsen)",
    url           => "https://github.com/jhthorsen",
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/jhthorsen/linkembedder' => {
    %expected,
    html          => qr{LinkEmbedder is a module},
    thumbnail_url => qr{githubusercontent.com/u/45729\b},
    title         => "jhthorsen/linkembedder: Embed / expand oEmbed resources and other URL / links",
    url           => "https://github.com/jhthorsen/linkembedder",
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t' => {
    %expected,
    html          => qr{linkembedder/basic\.t},
    thumbnail_url => qr{githubusercontent.com/u/45729\b},
    title         => "linkembedder/basic.t at master \x{b7} jhthorsen/linkembedder",
    url           => "https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t",
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/mojolicious/mojo/issues/729' => {
    %expected,
    html          => qr{The browser sends the value of the checkbox only if it is checked},
    thumbnail_url => qr{githubusercontent.com/u/},
    title         => "Validate <input type=\"checkbox\"> \x{b7} Issue #729 \x{b7} mojolicious/mojo",
    url           => "https://github.com/mojolicious/mojo/issues/729",
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/mojolicious/mojo/pull/1055' => {
    %expected,
    html          => qr{Exit early when the subprocess parent callback},
    thumbnail_url => qr{githubusercontent.com/u/},
    title         => "Proposed fix for #1054 by jberger \x{b7} Pull Request #1055 \x{b7} mojolicious/mojo",
    url           => "https://github.com/mojolicious/mojo/pull/1055",
  }
);

done_testing;
