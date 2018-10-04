use Mojo::Base -strict;
use Test::Deep;
use Test::More;
use LinkEmbedder;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $embedder = LinkEmbedder->new;

my $link;
$embedder->get_p('http://www.greatcirclemapper.net/en/great-circle-mapper.html?route=KJFK-VHHH&aircraft=&speed=')
  ->then(sub { $link = shift })->wait;
isa_ok($link, 'LinkEmbedder::Link::Basic');
cmp_deeply($link->provider_name, 'Greatcirclemapper', 'correct provider_name');
like $link->html, qr{class="le-card le-image-card le-rich le-provider-greatcirclemapper"}, 'correct class';

done_testing;
