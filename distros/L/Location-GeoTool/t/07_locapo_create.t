use strict;
use Test::More tests => 4;

use Location::GeoTool qw/Locapoint/;

my @testcase = (
  [
    35.606954,139.567104,'SD7.XC0.GF5.TT8'
  ],
  [
    -27.371768,-58.798831,'JB2.IT5.AZ7.XC7'
  ],
);

foreach my $testcase (@testcase)
{
  my ($lat,$long,$locapo) = @{$testcase};
  my $loc = Location::GeoTool->create_locapoint($locapo)->datum_wgs84->format_degree;
  is $loc->lat, $lat;
  is $loc->long, $long;
}

