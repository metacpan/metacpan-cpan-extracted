use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => "TEST_SHADOWCAT=586840" unless $ENV{TEST_SHADOWCAT};

LinkEmbedder->new->test_ok(
  "http://paste.scsys.co.uk/$ENV{TEST_SHADOWCAT}" => {
    isa           => 'LinkEmbedder::Link::Shadowcat',
    cache_age     => 0,
    html          => qr{<pre>use Mojo::Base},
    provider_name => 'Shadowcat',
    provider_url  => 'https://shadow.cat/',
    title         => "Paste $ENV{TEST_SHADOWCAT}",
    type          => 'rich',
    url           => "http://paste.scsys.co.uk/$ENV{TEST_SHADOWCAT}",
    version       => '1.0',
  }
);

done_testing;

my $TEST_PASTE_TO_SUBMIT = <<'HERE';
use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;
1;
HERE
