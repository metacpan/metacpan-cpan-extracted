#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 52;

use bytes;

BEGIN {
  use_ok('Ekahau::Server::Test',qw(static_location static_area));
  use_ok('Ekahau::Events',qw(:events));
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
my $client = Ekahau::Events->new(Socket => $client_sock,
				 Timeout => 10,
				 );
isa_ok($client,'Ekahau::Events');
$client
    or die "Couldn't create Ekahau client: ",Ekahau->lasterr."\n";

our $tag;
our(@dltest,@dl);
our $obj;

# Try a simple test first, with tags
$tag = $client->request_device_list();
ok($tag,'requested device list');
$tag or die "Error requesting device list: ",$client->lasterr;
$client->register_handler($tag,EKAHAU_EVENT_ANY,\&set_dltest);
$client->dispatch;
ok(@dltest == @test_devices,'register by tag');
@dl = @dltest;

# Test unregistering
$client->unregister_handler($tag,EKAHAU_EVENT_ANY);
@dltest = ();
$tag = $client->request_device_list();
ok($tag,'requested device list');
$tag or die "Error requesting device list: ",$client->lasterr;
$client->dispatch;
ok(@dltest == 0,'unregister by tag');

# Try register_once
@dltest=();
$tag = $client->request_device_list();
ok($tag,'requested device list');
$tag or die "Error requesting device list: ",$client->lasterr;
$client->register_handler_once($tag,EKAHAU_EVENT_ANY,\&set_dltest);
$client->dispatch;
ok(@dltest == @test_devices,'register_once by tag');
# Make sure automatic unregister worked.
@dltest = ();
$tag = $client->request_device_list();
$client->dispatch;
ok(@dltest == 0,'register_once unregistered');

# How about if we register by event?
@dltest = ();
$client->register_handler_once(EKAHAU_EVENT_ANY_TAG,EKAHAU_EVENT_DEVICE_LIST,\&set_dltest);
$tag = $client->request_device_list();
ok($tag,'requested device list');
$tag or die "Error requesting device list: ",$client->lasterr;
$client->dispatch;
ok(@dltest == @test_devices,'register by event');

# What if we register by both?
@dltest=();
$tag = $client->request_device_list();
ok($tag,'requested device list');
$tag or die "Error requesting device list: ",$client->lasterr;
$client->register_handler_once($tag,EKAHAU_EVENT_DEVICE_LIST,\&set_dltest);
$client->dispatch;
ok(@dltest == @test_devices,'register by tag and event');

# And the default?
@dltest=();
$tag = $client->request_device_list();
ok($tag,'requested device list');
$tag or die "Error requesting device list: ",$client->lasterr;
$client->register_handler_once(EKAHAU_EVENT_ANY_TAG,EKAHAU_EVENT_ANY,\&set_dltest);
$client->dispatch;
ok(@dltest == @test_devices,'register default event');

# OK.  Those are all the different ways to register for events.

# Let's try a few different events.

# Device Properties
$tag = $client->request_device_properties($dl[0]);
ok($tag,'requested device properties');
$tag or die "Error requesting device properties: ",$client->lasterr;
$client->register_handler_once($tag,EKAHAU_EVENT_ANY,\&rememberobj);
$client->dispatch;
ok($obj->type eq 'DeviceProperties','device properties response type');
ok($obj->eventname eq EKAHAU_EVENT_DEVICE_PROPERTIES,'device properties response event type');

# Area List
$tag = $client->request_all_areas();
ok($tag,'requested device properties');
$tag or die "Error requesting device properties: ",$client->lasterr;
$client->register_handler_once($tag,EKAHAU_EVENT_AREA_LIST,\&rememberobj);
$client->dispatch;
ok($obj->type eq 'AreaList','area list response type');
ok($obj->eventname eq EKAHAU_EVENT_AREA_LIST,'area list response event type');

# Get Context
$tag = $client->request_location_context('12345');
ok($tag,'requested device properties');
$tag or die "Error requesting device properties: ",$client->lasterr;
$client->register_handler_once($tag,EKAHAU_EVENT_LOCATION_CONTEXT,\&rememberobj);
$client->dispatch;
ok($obj->type eq 'LocationContext','get context response type');
ok($obj->eventname eq EKAHAU_EVENT_LOCATION_CONTEXT,'get context response event type');

# Get Map
$tag = $client->request_map_image('12345');
ok($tag,'requested map image');
$tag or die "Error requesting map image: ",$client->lasterr;
$client->register_handler_once($tag,EKAHAU_EVENT_MAP_IMAGE,\&rememberobj);
$client->dispatch;
ok($obj->type eq 'MapImage','get map image response type');
ok($obj->eventname eq EKAHAU_EVENT_MAP_IMAGE,'get map image response event type');


# OK, what about tracking?
$client->register_handler('LOC',EKAHAU_EVENT_ANY,\&rememberobj);

# Location Track
$tag = $client->start_location_track({ Tag => 'LOC' }, $dl[0]);
ok($tag,'start location track');
$tag or die "Error starting location track: ",$client->lasterr;
$client->dispatch;
ok($obj->type eq 'LocationEstimate','received location estimate');
$client->dispatch;
ok($obj->type eq 'LocationEstimate','received location estimate');
$tag = $client->stop_location_track({ Tag => 'LOC' }, $dl[0]);
ok($tag,'stopping location tracking');
$tag or die "Error requesting map image: ",$client->lasterr;
$client->dispatch;
ok($obj->type eq 'StopLocationTrackOK','location tracking stopped');

# Area Track
$tag = $client->start_area_track({ Tag => 'LOC' }, $dl[0]);
ok($tag,'start area track');
$tag or die "Error starting area track: ",$client->lasterr;
$client->dispatch;
ok($obj->type eq 'AreaEstimate','received area estimate');
$client->dispatch;
ok($obj->type eq 'AreaEstimate','received area estimate');
$tag = $client->stop_area_track({ Tag => 'LOC' }, $dl[0]);
ok($tag,'stopping area tracking');
$tag or die "Error requesting map image: ",$client->lasterr;
$client->dispatch;
ok($obj->type eq 'StopAreaTrackOK','area tracking stopped');

$client->unregister_handler('LOC',EKAHAU_EVENT_ANY,\&rememberobj);

# Error handling
$client->register_handler(EKAHAU_EVENT_ANY_TAG,EKAHAU_EVENT_ERROR,\&rememberobj);

$tag = $client->start_area_track(999);
ok($tag,'start area track');
$tag or die "Error starting area track: ",$client->lasterr;
$client->dispatch;
ok($obj->error,'got area track error OK');
undef $obj;

$tag = $client->request_device_properties(888);
ok($tag,'request device properties');
$tag or die "Error requesting device properties: ",$client->lasterr;
$client->dispatch;
ok($obj->error,'got device properties error OK');
undef $obj;

$tag = $client->request_location_context('NOSUCHPLACE');
ok($tag,'request location context');
$tag or die "Error requesting location context: ",$client->lasterr;
$client->dispatch;
ok($obj->error,'got location context error OK');
undef $obj;

$client->unregister_handler(EKAHAU_EVENT_ANY_TAG,EKAHAU_EVENT_ERROR,\&rememberobj);

# Event priority
my $who_handled;
$client->register_handler_once(EKAHAU_EVENT_ANY_TAG,EKAHAU_EVENT_ANY,sub { $who_handled = 'default' });
$client->register_handler_once(EKAHAU_EVENT_ANY_TAG,EKAHAU_EVENT_LOCATION_ESTIMATE,sub { $who_handled = 'event' });
$client->register_handler_once('test_tag',EKAHAU_EVENT_ANY,sub { $who_handled = 'tag' });
$client->register_handler_once('test_tag',EKAHAU_EVENT_LOCATION_ESTIMATE,sub { $who_handled = 'both' });

$tag = $client->start_location_track({ Tag => 'test_tag' }, $dl[0]);
ok($tag,'request device properties');
$tag or die "Error requesting device properties: ",$client->lasterr;

$client->dispatch;
ok($who_handled eq 'both','handler priority both');

$client->dispatch;
ok($who_handled eq 'tag','handler priority tag');

$client->dispatch;
ok($who_handled eq 'event','handler priority event');

$client->dispatch;
ok($who_handled eq 'default','handler priority default');


$tag = $client->stop_location_track({ Tag => 'LOC' }, $dl[0]);
ok($tag,'stopping location tracking');
$client->register_handler_once($tag,EKAHAU_EVENT_ANY,\&rememberobj);
$tag or die "Error requesting map image: ",$client->lasterr;
$client->dispatch;
ok($obj->type eq 'StopLocationTrackOK','location tracking stopped');







sub set_dltest
{
    my($dl_resp)=@_; 
    @dltest = $dl_resp->devices;
}

sub rememberobj
{
    $obj = shift;
}
