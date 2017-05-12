use strict;
use Test::More tests => 33;

BEGIN { use_ok 'Location::GeoTool' }

my %testcase = (
  61 => 
  {
    4 => ['Åì','E'],
    8 => ['ËÌÅì','NE'],
    16 => ['ÅìËÌÅì','ENE'],
    32 => ['ËÌÅìÈùÅì','NEbE']
  },
  124 => 
  {
    4 => ['Åì','E'],
    8 => ['ÆîÅì','SE'],
    16 => ['ÆîÅì','SE'],
    32 => ['ÆîÅìÈùÅì','SEbE']
  },
  247 => 
  {
    4 => ['À¾','W'],
    8 => ['ÆîÀ¾','SW'],
    16 => ['À¾ÆîÀ¾','WSW'],
    32 => ['À¾ÆîÀ¾','WSW']
  },
  324 => 
  {
    4 => ['ËÌ','N'],
    8 => ['ËÌÀ¾','NW'],
    16 => ['ËÌÀ¾','NW'],
    32 => ['ËÌÀ¾ÈùÀ¾','NWbW']
  }
);

my $obj = Location::GeoTool->create_coord(35.12345,139.12345,'wgs84','degree');

foreach my $degree (keys %testcase)
{
  my $dir = $obj->direction_vector($degree,100);
  foreach my $mother (keys %{$testcase{$degree}})
  {
    my @string = @{$testcase{$degree}->{$mother}};
    is $dir->dir_string($mother,'jp'),$string[0];
    is $dir->dir_string($mother,'en'),$string[1];
  }
}

