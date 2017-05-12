#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Geo::Coder::Ovi;

my $location = join(' ', @ARGV) || die "Usage: $0 \$location_string";

# Custom useragent identifier.
my $ua = LWP::UserAgent->new(agent => 'My Geocoder');

# Load any proxy settings from environment variables.
$ua->env_proxy;

my $geocoder = Geo::Coder::Ovi->new(
    ua    => $ua,
    debug => 1,
);
my $result = $geocoder->geocode(location => $location);

local $Data::Dumper::Indent = 1;
print Dumper($result);
