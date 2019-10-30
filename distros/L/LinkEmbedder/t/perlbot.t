use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_PERLBOT=xogtbq'   unless $ENV{TEST_PERLBOT};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my $embedder = LinkEmbedder->new;

my $link;
$embedder->get_p("https://perlbot.pl/p/$ENV{TEST_PERLBOT}")->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Basic');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => re(qr{<pre>use Mojo::Base}),
    provider_name => 'Perlbot',
    provider_url  => 'https://perlbot.pl/',
    title         => re(qr{Perlbot Pastebin}),
    type          => 'rich',
    url           => "https://perlbot.pl/p/$ENV{TEST_PERLBOT}",
    version       => '1.0',
  },
  'https://perlbot.pl'
) or note $link->_dump;

done_testing;

my $TEST_PASTE_TO_SUBMIT = <<'HERE';
use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;
HERE
