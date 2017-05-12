use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;
my $link;

$link = $embedder->get('https://gist.github.com/9604bd5f3c9c4f3620d0daedbdab975d');
isa_ok($link, 'LinkEmbedder::Link::Github');

is $link->type, 'rich', 'rich anonymous gist';
like $link->html, qr{le-paste le-rich le-provider-github.*Mojo::Server::Morbo::Backend::Inotify}s, 'anonymous gist';

$link = $embedder->get('https://gist.github.com/jhthorsen/3738de6f44f180a29bbb');
isa_ok($link, 'LinkEmbedder::Link::Github');
like $link->html, qr{le-paste le-rich le-provider-github.*this\.removeEventListener}s, 'jhthorsen gist';

$link = $embedder->get('https://gist.github.com/jhthorsen/3738de6f44f180a29bbb/revisions');
isa_ok($link, 'LinkEmbedder::Link::Github');
like $link->html, qr{le-paste le-rich le-provider-github.*this\.removeEventListener}s, 'revisions gist';

$link
  = $embedder->get('https://gist.github.com/jhthorsen/3738de6f44f180a29bbb/5a20afa90e97c0e8d3ef8000b17a3800c08d1870');
isa_ok($link, 'LinkEmbedder::Link::Github');
like $link->html, qr{le-paste le-rich le-provider-github.*this\.removeEventListener}s, 'revision gist';

done_testing;
