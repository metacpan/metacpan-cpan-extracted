use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => "TEST_SHADOWCAT=586840" unless $ENV{TEST_SHADOWCAT};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p("http://paste.scsys.co.uk/$ENV{TEST_SHADOWCAT}")->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Shadowcat');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => re(qr{<pre>use Mojo::Base}),
    provider_name => 'Shadowcat',
    provider_url  => 'https://shadow.cat/',
    title         => "Paste $ENV{TEST_SHADOWCAT}",
    type          => 'rich',
    url           => "http://paste.scsys.co.uk/$ENV{TEST_SHADOWCAT}",
    version       => '1.0',
  },
  'http://paste.scsys.co.uk/',
) or note $link->_dump;

done_testing;

my $TEST_PASTE_TO_SUBMIT = <<'HERE';
use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;
HERE
