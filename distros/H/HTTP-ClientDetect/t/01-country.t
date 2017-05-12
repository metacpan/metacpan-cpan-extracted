#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 5;
use File::Spec;
use Data::Dumper;

# fake a request

use Interchange6::Plugin::Interchange5::Request;
use HTTP::ClientDetect::Location;


my $env = {
           REMOTE_ADDR => '128.31.0.51',
          };
my $request = Interchange6::Plugin::Interchange5::Request->new(env => $env);

my $dbfile = File::Spec->catfile(t => 'GeoIP.dat');

my $geo = HTTP::ClientDetect::Location->new(db => $dbfile);

# testing if geo_ip works calling it.

my $ip = $geo->geo->country_code_by_addr("128.31.0.51") || "";
ok($ip, "Found country code of 128.31.0.51: $ip");
my $host = $geo->geo->country_code_by_name("linuxia.de") || "";
ok($host, "Found country code of linuxia.de: $host");

ok ($request->remote_address, "Object OK");

foreach my $obj ("128.31.0.51", $request) {
    my $country = $geo->request_country($obj) || "";
    ok ($country, "Found $country");
}

