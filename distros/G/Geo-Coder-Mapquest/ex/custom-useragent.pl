#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Geo::Coder::Mapquest;

unless ($ENV{MAPQUEST_APIKEY}) {
    die "MAPQUEST_APIKEY environment variable must be set";
}
my $location = join(' ', @ARGV) || die "Usage: $0 \$location_string";

# Custom useragent identifier.
my $ua = LWP::UserAgent->new(agent => 'My Geocoder');

# Allow compressed replies.
if (eval "use Compress::Zlib") {
    $ua->default_headers(accept_encoding => 'gzip,deflate');
}

# Load any proxy settings from environment variables.
$ua->env_proxy;

my $geocoder = Geo::Coder::Mapquest->new(
    apikey => $ENV{MAPQUEST_APIKEY},
    ua     => $ua,
    debug  => 1,
);
my $result = $geocoder->geocode(location => $location);

local $Data::Dumper::Indent = 1;
print Dumper($result);
