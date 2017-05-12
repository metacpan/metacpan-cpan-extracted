#!/usr/bin/perl -w
 
use strict;
use Data::Dumper;
 
use Test::More tests => 48;

BEGIN {
  use_ok('Ekahau::Server::Test',qw(static_location static_area));
  use_ok('Ekahau');
}

use vars qw(@test_devices %test_ctx %test_maps);
do 't/testdata.pl'
    or die "Couldn't include data\n";

my $client_sock = Ekahau::Server::Test::Background->start(
    Tick => 1,
    Devices => \@test_devices,
    Contexts => \%test_ctx,
    Maps => \%test_maps,
  );
ok($client_sock,'starting background server');
$client_sock
    or die "Couldn't create background server: $!\n";
my $client;
eval {
    $client = Ekahau->new(Socket => $client_sock,
			  Timeout => 10,
			  );
};
isa_ok($client,'Ekahau');
$client
    or die "Couldn't create Ekahau client.\n";

my $dl = $client->get_device_list();
is_deeply($dl,[1],'correct get_device_list response');

my $prop = $client->get_device_properties($dl->[0]);
isa_ok($prop,'Ekahau::Response::DeviceProperties');
$prop
    or die "Couldn't get device properties: $client->{err}\n";

# Start tracking locations.
my($track1,$track2);
ok($client->start_location_track($dl->[0]));
$track1 = $client->next_location;
isa_ok($track1,'Ekahau::Response::LocationEstimate');

$track2 = $client->next_location;
isa_ok($track2,'Ekahau::Response::LocationEstimate');

# The two time properties should be different...
ok(delete $track1->{params}{accurateTime} != delete $track2->{params}{accurateTime});
ok(delete $track1->{params}{latestTime} != delete $track2->{params}{latestTime});
# ...and everything else identical.
eq_hash($track1,$track2);

ok($client->stop_location_track($dl->[0]));

# Track some areas
ok($client->start_area_track($dl->[0]));

$track1 = $client->next_area;
isa_ok($track1,'Ekahau::Response::AreaEstimate');

$track2 = $client->next_area;
isa_ok($track2,'Ekahau::Response::AreaEstimate');

# Should be identical, except for string, which may vary slightly.
delete $track1->{string};
delete $track2->{string};
is_deeply($track1,$track2);

ok($client->stop_area_track($dl->[0]));


# More complicated area track

ok($client->start_area_track({ 'EPE.NUMBER_OF_AREAS' => 3 }, $dl->[0]));

$track1 = $client->next_area;
isa_ok($track1,'Ekahau::Response::AreaEstimate');

my @al = $track1->get_all;
ok(@al == 3);
isa_ok($al[0],'Ekahau::Response::Area');
isa_ok($al[1],'Ekahau::Response::Area');
isa_ok($al[2],'Ekahau::Response::Area');
ok(($al[0]->get_prop('name') eq 'area51'
   and $al[0]->get_prop('probability') == 80.0),'area 0 name and probability');
ok(($al[1]->get_prop('name') eq 'pi_r_squared'
   and $al[1]->get_prop('probability') == 20.0),'area 1 name and probability');
ok($al[2]->get_prop('probability') == 0,'area 2 probability');

$track2 = $client->next_area;
isa_ok($track2,'Ekahau::Response::AreaEstimate');
# Should be identical, except for string, which may vary slightly.
delete $track1->{string};
delete $track2->{string};
is_deeply($track1,$track2);

ok($client->stop_area_track($dl->[0]));


# Overlapping requests
ok($client->start_track({ 'EPE.NUMBER_OF_AREAS' => 5 }, $dl->[0]));
$track1 = $client->next_area;
isa_ok($track1,'Ekahau::Response::AreaEstimate');
@al = $track1->get_all;
ok(@al == 5);
isa_ok($al[1],'Ekahau::Response::Area');
ok($al[1]->get_prop('contextId') eq '23456','area 1 context ID');
my $ctx = $client->get_location_context($al[1]->get_prop('contextId'));
isa_ok($ctx,'Ekahau::Response::LocationContext');
ok(($ctx->get_prop('address') eq 'building/floor2' and
    $ctx->get_prop('mapScale') == 10 and
    $ctx->get_prop('property2') eq 'value2'),'value of context 23456');

$track2 = $client->next_area;
isa_ok($track2,'Ekahau::Response::AreaEstimate');
# Should be identical, except for string, which may vary slightly.
delete $track1->{string};
delete $track2->{string};
is_deeply($track1,$track2);

$track2 = $client->next_area;
isa_ok($track2,'Ekahau::Response::AreaEstimate');
# Should be identical, except for string, which may vary slightly.
delete $track1->{string};
delete $track2->{string};
is_deeply($track1,$track2);

$track1 = $client->next_location;
isa_ok($track1,'Ekahau::Response::LocationEstimate');
ok($track1->get_prop('accurateContextId') eq '12345','context id 12345');
$ctx = $client->get_location_context($track1->get_prop('accurateContextId'));
isa_ok($ctx,'Ekahau::Response::LocationContext');
ok(($ctx->get_prop('address') eq 'building/floor1' and
    $ctx->get_prop('mapScale') == 10 and
    $ctx->get_prop('property1') eq 'value1'),'value of context 12345');

$track2 = $client->next_location;
isa_ok($track2,'Ekahau::Response::LocationEstimate');

# The two time properties should be different...
ok(delete $track1->{params}{accurateTime} != delete $track2->{params}{accurateTime});
ok(delete $track1->{params}{latestTime} != delete $track2->{params}{latestTime});
# The strings can vary slightly
delete $track1->{string};
delete $track2->{string};
# ...and everything else identical.
eq_hash($track1,$track2);

ok($client->stop_track($dl->[0]));
