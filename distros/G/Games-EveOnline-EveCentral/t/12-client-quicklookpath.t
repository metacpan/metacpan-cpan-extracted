#!perl

BEGIN { chdir 't' if -d 't' }

use lib 'lib';

use Test::More tests => 4;
use Test::Mock::Class 0.0303 qw(:all);

use Games::EveOnline::EveCentral;
use Games::EveOnline::EveCentral::Request::QuickLookPath;

use Games::EveOnline::EveCentral::Tests qw(fake_http_response);
require LWP::UserAgent::Determined;

mock_class 'LWP::UserAgent::Determined' => 'LWP::UserAgent::Determined::Mock';
my $lwp = LWP::UserAgent::Determined::Mock->new;
$lwp->mock_return(
  get => fake_http_response('res/quicklook-path.xml'), args => [qr//]
);

my $client = Games::EveOnline::EveCentral->new(ua => $lwp);
isa_ok($client, 'Games::EveOnline::EveCentral');

my $xml = $client->quicklookpath(
  Games::EveOnline::EveCentral::Request::QuickLookPath->new(
    type_id => 34,
    from_system => 'Jita',
    to_system => 'Amarr'
  )->request
);
my $parser = $client->libxml;
my $doc = $parser->parse_string($xml);

my $type_id = $doc->findvalue('//quicklook/item/text()');
is($type_id, '34');

my @jita_orders = $doc->findnodes(
  '//quicklook/sell_orders/order/station[text() = "60003760"]'
);
isnt(scalar @jita_orders, 0);

my @amarr_orders = $doc->findnodes(
  '//quicklook/sell_orders/order/station[text() = "60008494"]'
);
isnt(scalar @amarr_orders, 0);

$lwp->mock_tally;
