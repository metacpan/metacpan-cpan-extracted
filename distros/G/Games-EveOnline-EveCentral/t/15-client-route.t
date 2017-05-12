#!perl

BEGIN { chdir 't' if -d 't' }

use lib 'lib';

use Test::More tests => 4;
use Test::Mock::Class 0.0303 qw(:all);

use Games::EveOnline::EveCentral;
use Games::EveOnline::EveCentral::Request::Route;

use Games::EveOnline::EveCentral::Tests qw(fake_http_response);
require LWP::UserAgent::Determined;

mock_class 'LWP::UserAgent::Determined' => 'LWP::UserAgent::Determined::Mock';
my $lwp = LWP::UserAgent::Determined::Mock->new;
$lwp->mock_return(
  get => fake_http_response('res/route.json'), args => [qr//]
);

my $client = Games::EveOnline::EveCentral->new(ua => $lwp);
isa_ok($client, 'Games::EveOnline::EveCentral');

my $json = $client->route(
  Games::EveOnline::EveCentral::Request::Route->new(
    from_system => 'Jita',
    to_system => 'V2-VC2'
  )->request
);
my $parser = $client->jsonparser;
my $json_object = $parser->decode($json);
is(scalar @{$json_object}, 35);
is($json_object->[0]->{from}->{name}, 'Jita');
is($json_object->[34]->{to}->{name}, 'V2-VC2');

$lwp->mock_tally;
