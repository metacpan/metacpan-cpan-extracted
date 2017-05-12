#!perl

BEGIN { chdir 't' if -d 't' }

use lib 'lib';

use Test::More tests => 2;
use Test::Mock::Class 0.0303 qw(:all);

use Games::EveOnline::EveCentral;
use Games::EveOnline::EveCentral::Request::History;

use Games::EveOnline::EveCentral::Tests qw(fake_http_response);
require LWP::UserAgent::Determined;

mock_class 'LWP::UserAgent::Determined' => 'LWP::UserAgent::Determined::Mock';
my $lwp = LWP::UserAgent::Determined::Mock->new;
$lwp->mock_return(
  get => fake_http_response('res/history-system.json'), args => [qr//]
);

my $client = Games::EveOnline::EveCentral->new(ua => $lwp);
isa_ok($client, 'Games::EveOnline::EveCentral');

my $json = $client->history(
  Games::EveOnline::EveCentral::Request::History->new(
    type_id => 34,
    location_type => 'system',
    location => 'Amarr',
    bid => 'buy'
  )->request
);
my $parser = $client->jsonparser;
my $json_object = $parser->decode($json);
is(scalar @{$json_object->{values}}, 164);

$lwp->mock_tally;
