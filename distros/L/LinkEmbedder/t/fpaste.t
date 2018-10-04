use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my $link;
$embedder->get_p('https://paste.fedoraproject.org/paste/9qkGGjN-D3fL2M-bimrwNQ')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Fpaste');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => re(qr{<pre>use LinkEmbedder;}),
    provider_name => 'Fedoraproject',
    provider_url  => 'https://fedoraproject.org/',
    title         => re(qr{LinkEmbedder test}),
    type          => 'rich',
    url           => 'https://paste.fedoraproject.org/paste/9qkGGjN-D3fL2M-bimrwNQ',
    version       => '1.0',
  },
  'paste.fedoraproject.org'
) or note $link->_dump;

done_testing;
