use strict;
use Test::More tests => 2;

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
  my $loc = Location::GeoTool->create_coord($lat,$long,'wgs84','degree');
  is $loc->get_locapoint, $locapo;
}

