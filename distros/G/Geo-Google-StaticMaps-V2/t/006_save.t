# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 1 + 3 * 4;
BEGIN { use_ok( 'Geo::Google::StaticMaps::V2' ); }

my $map=Geo::Google::StaticMaps::V2->new();
$map->marker(location=>"Clifton,VA");

foreach my $ext (qw{png gif jpg}) {
  my $file="google_staticmap.$ext";
  unlink $file if -f $file;

  ok(not -f $file);

  ok(not defined($map->format));
  #$map->format($ext);
  $map->save($file);
  ok(not defined($map->format));

  ok(-f $file);
}
