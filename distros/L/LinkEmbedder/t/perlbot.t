use Mojo::Base -strict;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_PERLBOT=xogtbq'   unless $ENV{TEST_PERLBOT};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

LinkEmbedder->new->test_ok(
  "https://perlbot.pl/p/$ENV{TEST_PERLBOT}" => {
    isa           => 'LinkEmbedder::Link::Basic',
    cache_age     => 0,
    html          => qr{<pre>use Mojo::Base},
    provider_name => 'Perlbot',
    provider_url  => 'https://perlbot.pl/',
    title         => qr{Perlbot Pastebin},
    type          => 'rich',
    url           => "https://perlbot.pl/p/$ENV{TEST_PERLBOT}",
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
