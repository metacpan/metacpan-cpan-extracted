use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_SHADOWCAT=1' unless $ENV{TEST_SHADOWCAT};

my $embedder = LinkEmbedder->new;
my $link;
$embedder->get_p('http://paste.scsys.co.uk/586337')->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Shadowcat');
cmp_deeply(
  $link->TO_JSON,
  {
    cache_age     => 0,
    html          => re(qr{<pre>&lt;too&gt;cool!&lt;/too&gt;</pre>}),
    provider_name => 'Shadowcat',
    provider_url  => 'http://shadow.cat/',
    title         => 'Paste 586337',
    type          => 'rich',
    url           => 'http://paste.scsys.co.uk/586337',
    version       => '1.0',
  },
  'http://paste.scsys.co.uk/586337',
) or note $link->_dump;

done_testing;
