use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_FEDORA=TdDtYw1YSaEDqIOqVYlWbw' unless $ENV{TEST_FEDORA};
plan skip_all => 'cpanm IO::Socket::SSL' unless LinkEmbedder::TLS;

my $embedder = LinkEmbedder->new;

my $link;
$embedder->get_p("https://paste.fedoraproject.org/paste/$ENV{TEST_FEDORA}")->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Fpaste');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => re(qr{<pre>use Mojo::Base}),
    provider_name => 'Fedoraproject',
    provider_url  => 'https://fedoraproject.org/',
    title         => re(qr{Modern Paste}),
    type          => 'rich',
    url           => "https://paste.fedoraproject.org/paste/$ENV{TEST_FEDORA}",
    version       => '1.0',
  },
  'paste.fedoraproject.org'
) or note $link->_dump;

done_testing;

my $TEST_PASTE_TO_SUBMIT = <<'HERE';
use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;
HERE
