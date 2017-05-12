#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 26;

use bytes;

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

# Test get_all_areas
my $al_resp = $client->get_all_areas;
isa_ok($al_resp,'Ekahau::Response::AreaList');
my @al = $al_resp->get_all;
ok(@al == 2,'Area list count');
isa_ok($al[0],'Ekahau::Response::Area');
isa_ok($al[1],'Ekahau::Response::Area');
if ($al[0]->get_prop('name') eq '12345')
{
    ok( ($al[0]->get_prop('name') eq '12345' and
	 $al[0]->get_prop('address') eq 'building/floor1' and
	 $al[0]->get_prop('mapScale') == 10 and
	 $al[0]->get_prop('property1') eq 'value1'),'area 12345 properties');
    ok( ($al[1]->get_prop('name') eq '23456' and
	 $al[1]->get_prop('address') eq 'building/floor2' and
	 $al[1]->get_prop('mapScale') == 10 and
	 $al[1]->get_prop('property2') eq 'value2'),'area 23456 properties');

}
else
{
    ok( ($al[1]->get_prop('name') eq '12345' and
	 $al[1]->get_prop('address') eq 'building/floor1' and
	 $al[1]->get_prop('mapScale') == 10 and
	 $al[1]->get_prop('property1') eq 'value1'),'area 12345 properties');
    ok( ($al[0]->get_prop('name') eq '23456' and
	 $al[0]->get_prop('address') eq 'building/floor2' and
	 $al[0]->get_prop('mapScale') == 10 and
	 $al[0]->get_prop('property2') eq 'value2'),'area 23456 properties');

}


# Test get_map_image
foreach my $area (qw(12345 23456 34567))
{
    my $map = $client->get_map_image($area);
    isa_ok($map,'Ekahau::Response::MapImage');
    ok($map->map_size == length($test_maps{$area}),"size of map $area");
    is($map->map_type,'png',"type for map $area");
    is($map->map_image,$test_maps{$area},"data for map $area");
}

# Test a few errors
my $resp;

$resp = $client->get_device_properties('888');
ok(!$resp,'get_device_properties returns error correctly');

$resp = $client->get_location_context('98765');
ok(!$resp,'get_location_context returns error correctly');

$client->start_location_track('888');
$resp = $client->next_track;
ok($resp->error,'location_track returns error correctly');

$client->start_area_track('888');
$resp = $client->next_track;
ok($resp->error,'area_track returns error correctly');

