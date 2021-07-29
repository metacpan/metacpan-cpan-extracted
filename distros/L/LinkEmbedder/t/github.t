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
  'https://github.com/convos-chat/linkembedder/blob/master/examples/embedder.pl' => {
    %expected,
    isa           => 'LinkEmbedder::Link::Github',
    html          => qr{use Mojolicious::Lite;\n\nuse lib.*decodeURIComponent}s,
    thumbnail_url => qr{opengraph\.githubassets\.com/},
    title         => qr{embedder\.pl},
    url           => 'https://github.com/convos-chat/linkembedder/blob/master/examples/embedder.pl',
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/convos-chat/linkembedder/blob/4e0307a369651758839677a4c453f6988c933ad0/Changes#L14-L16' =>
    {html => qr{<pre>1\.12 2020-03-24T12:12:10.*text as a paste\s+</pre>}s});

LinkEmbedder->new->test_ok(
  'https://github.com/convos-chat/linkembedder/blob/4e0307a369651758839677a4c453f6988c933ad0/Changes#L16' =>
    {html => qr{<pre>\s-\sWill serve plain text as a paste.*placeholder_url\s+</pre>}s});

LinkEmbedder->new->test_ok(
  'https://git.io/aKhMuA' => {
    isa => 'LinkEmbedder::Link::Github',
    %expected,
    html          => qr{simplest way.*IRC},
    thumbnail_url => qr{opengraph\.githubassets\.com/},
    title         => "Add back compat redirect from /convos to / \x{b7} convos-chat/convos\@668368b",
    url           => "https://git.io/aKhMuA",
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/jhthorsen' => {
    %expected,
    isa           => 'LinkEmbedder::Link::Github',
    html          => qr{Follow their code on GitHub},
    thumbnail_url => qr{avatars\.githubusercontent\.com/u},
    title         => qr{jhthorsen},
    url           => "https://github.com/jhthorsen",
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/convos-chat/linkembedder' => {
    %expected,
    html          => qr{LinkEmbedder is a module},
    thumbnail_url => qr{opengraph\.githubassets\.com/},
    title         => "convos-chat/linkembedder: Embed / expand oEmbed resources and other URL / links",
    url           => "https://github.com/convos-chat/linkembedder",
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/convos-chat/convos/issues/607' => {
    %expected,
    html          => qr{div.*le-rich.*h3.*Search for &quot;\+&quot;.*le-description.*When I type &quot;\+&quot;}s,
    thumbnail_url => qr{opengraph\.githubassets\.com},
    title         => qr{Search for "\+"},
    url           => "https://github.com/convos-chat/convos/issues/607",
  }
);

LinkEmbedder->new->test_ok(
  'https://github.com/mojolicious/mojo/pull/1055' => {
    %expected,
    html          => qr{Exit early when the subprocess parent callback},
    thumbnail_url => qr{opengraph\.githubassets\.com/},
    title         => "Proposed fix for #1054 by jberger \x{b7} Pull Request #1055 \x{b7} mojolicious/mojo",
    url           => "https://github.com/mojolicious/mojo/pull/1055",
  }
);

done_testing;
