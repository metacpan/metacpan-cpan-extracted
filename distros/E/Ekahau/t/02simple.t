#!/usr/bin/perl -w
 
use strict;
 
use Test::More tests => 7;

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

my $client = Ekahau->new(Socket => $client_sock,
			 Timeout => 10,
			 );
isa_ok($client,'Ekahau','creating Ekahau client');
$client
    or die "Couldn't create Ekahau client\n";

my $dl = $client->get_device_list;
ok($dl,'getting device list');
$dl
    or die "Couldn't get device list: $client->{err}\n";
ok(@$dl == @test_devices,'analyzing device list');
@$dl or die "No devices to track\n";

my $prop = $client->get_device_properties($dl->[0]);
isa_ok($prop,'Ekahau::Response::DeviceProperties','getting device properties');
$prop
    or die "Couldn't get device properties: $client->{err}\n";
