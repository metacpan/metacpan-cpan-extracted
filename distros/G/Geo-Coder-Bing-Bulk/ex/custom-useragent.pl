#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Geo::Coder::Bing::Bulk;

unless ($ENV{BING_MAPS_KEY}) {
    die "BING_MAPS_KEY environment variable must be set";
}

die "Usage: $0 \$location_string ..." unless @ARGV;

# Custom useragent identifier.
my $ua = LWP::UserAgent->new(agent => 'My Bulk Geocoder');

# Load any proxy settings from environment variables.
$ua->env_proxy;

my $bulk = Geo::Coder::Bing::Bulk->new(
    key      => $ENV{BING_MAPS_KEY},
    https    => 1,
    ua       => $ua,
    debug    => 1,
);

my $id = $bulk->upload(\@ARGV);
sleep 30 while $bulk->is_pending;
my $data = $bulk->download;

local $Data::Dumper::Indent = 1;
print Dumper($data);
