use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my %expected = (
  cache_age     => '0',
  provider_name => 'GitHub',
  provider_url  => 'https://github.com',
  type          => 'rich',
  version       => '1.0',
);

my $embedder = LinkEmbedder->new;
my $link;

$link = $embedder->get('http://git.io/aKhMuA');
isa_ok($link, 'LinkEmbedder::Link::Github');
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    html          => re(qr{Better group chat}),
    thumbnail_url => re(qr{githubusercontent\.com/u/45729\b}),
    title         => "Add back compat redirect from /convos to / \x{b7} Nordaaker/convos\@668368b",
    url           => "http://git.io/aKhMuA",
  },
  'http://git.io/aKhMuA',
) or note $link->_dump;

$link = $embedder->get('https://github.com/jhthorsen');
isa_ok($link, 'LinkEmbedder::Link::Github');
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    html          => re(qr{Follow their code on GitHub}),
    thumbnail_url => re(qr{githubusercontent.com/u/45729\b}),
    title         => "jhthorsen (Jan Henning Thorsen)",
    url           => "https://github.com/jhthorsen",
  },
  'https://github.com/jhthorsen'
) or note $link->_dump;

$link = $embedder->get('https://github.com/jhthorsen/linkembedder');
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    html          => re(qr{LinkEmbedder is a module}),
    thumbnail_url => re(qr{githubusercontent.com/u/45729\b}),
    title         => "jhthorsen/linkembedder: Embed / expand oEmbed resources and other URL / links",
    url           => "https://github.com/jhthorsen/linkembedder",
  },
  'https://github.com/jhthorsen/linkembedder'
) or note $link->_dump;

$link = $embedder->get('https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t');
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    html          => re(qr{linkembedder/basic\.t}),
    thumbnail_url => re(qr{githubusercontent.com/u/45729\b}),
    title         => "linkembedder/basic.t at master \x{b7} jhthorsen/linkembedder",
    url           => "https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t",
  },
  'https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t',
) or note $link->_dump;

$link = $embedder->get('https://github.com/kraih/mojo/issues/729');
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    html          => re(qr{The browser sends the value of the checkbox only if it is checked}),
    thumbnail_url => re(qr{githubusercontent.com/u/737152\b}),
    title         => "Validate <input type=\"checkbox\"> \x{b7} Issue #729 \x{b7} kraih/mojo",
    url           => "https://github.com/kraih/mojo/issues/729",
  },
  'https://github.com/kraih/mojo/issues/729',
) or note $link->_dump;

$link = $embedder->get('https://github.com/kraih/mojo/pull/1055');
cmp_deeply(
  $link->TO_JSON,
  {
    %expected,
    html          => re(qr{Exit early when the subprocess parent callback}),
    thumbnail_url => re(qr{githubusercontent.com/u/735765\b}),
    title         => "Proposed fix for #1054 by jberger \x{b7} Pull Request #1055 \x{b7} kraih/mojo",
    url           => "https://github.com/kraih/mojo/pull/1055",
  },
  'https://github.com/kraih/mojo/pull/1055',
) or note $link->_dump;

done_testing;
