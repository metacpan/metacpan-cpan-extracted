use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1'         unless $ENV{TEST_ONLINE};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  'https://gist.github.com/9604bd5f3c9c4f3620d0daedbdab975d' => {
    html => qr{le-paste le-rich le-provider-github.*Mojo::Server::Morbo::Backend::Inotify}s,
    isa  => 'LinkEmbedder::Link::Github',
    type => 'rich',
  }
);

LinkEmbedder->new->test_ok(
  'https://gist.github.com/jhthorsen/3738de6f44f180a29bbb' => {
    html => qr{le-paste le-rich le-provider-github.*this\.removeEventListener}s,
    isa  => 'LinkEmbedder::Link::Github',
    type => 'rich',
  }
);

LinkEmbedder->new->test_ok(
  'https://gist.github.com/jhthorsen/3738de6f44f180a29bbb/revisions' => {
    html => qr{le-paste le-rich le-provider-github.*this\.removeEventListener}s,
    isa  => 'LinkEmbedder::Link::Github',
    type => 'rich',
  }
);

LinkEmbedder->new->test_ok(
  'https://gist.github.com/jhthorsen/3738de6f44f180a29bbb/5a20afa90e97c0e8d3ef8000b17a3800c08d1870' => {
    html => qr{le-paste le-rich le-provider-github.*this\.removeEventListener}s,
    isa  => 'LinkEmbedder::Link::Github',
    type => 'rich',
  }
);

done_testing;
