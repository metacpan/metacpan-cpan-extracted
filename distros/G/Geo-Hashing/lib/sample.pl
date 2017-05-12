#!/usr/bin/perl -w
#
# $Id: sample.pl 255 2008-06-21 03:48:46Z dan $

use strict;
use Geo::Hashing;

# get the date from the commandline, or assume it's today's date
my $date = shift ||
             sprintf("%04d-%02d-%02d", (localtime)[5]+1900,
                                       (localtime)[4]+1,
                                       (localtime)[3]);

die "Usage: $0 <date> [<lat,lon>]"
  unless $date and $date =~ /^\d\d\d\d-\d\d-\d\d$/;

my ($lat, $lon) = (0, 0);
if (@ARGV) {
  ($lat, $lon) = split /\s*,\s*/, "@ARGV";
}

die "Invalid Lat/Lon!" unless $lat =~ /^-?\d+$/ and $lon =~ /^-?\d+$/;

my $geo = new Geo::Hashing(lat => $lat, lon => $lon, date => $date);
print "30W rule is in effect\n" if $geo->use_30w_rule;
printf "Geohash for $date ($lat, $lon): %0.6f, %0.6f\n", $geo->lat, $geo->lon;

