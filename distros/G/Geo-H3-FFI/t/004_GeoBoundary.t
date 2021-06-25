use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 25;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 25 unless $lib;

  require_ok 'Geo::H3::FFI';

  my $obj = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  my $index      = '622236750694711295';
  my $gb         = $obj->gb;
  isa_ok($gb, 'Geo::H3::FFI::Struct::GeoBoundary');

  my $void       = $obj->h3ToGeoBoundary($index, $gb);
  isa_ok($gb, 'Geo::H3::FFI::Struct::GeoBoundary');
  #diag(Dumper({gb=>$gb}));

  can_ok($gb, 'num_verts');
  can_ok($gb, 'verts');
  is($gb->num_verts, 6, '$gb->num_verts');

  #diag(Dumper({verts=>$verts}));

  foreach my $index (0 .. $gb->num_verts - 1) {
    my $vert = $gb->verts->[$index]; #$gb->verts sizeof 10
    #diag(Dumper({vert=>$vert}));
    isa_ok($vert, 'Geo::H3::FFI::Struct::GeoCoord');
    can_ok($vert, 'lat');
    can_ok($vert, 'lon');
    diag(sprintf("Count: %s, Lat: %s (%s), Lon: %s (%s)", $index, $vert->lat, $obj->radsToDegs($vert->lat),
                                                                  $vert->lon, $obj->radsToDegs($vert->lon)));
  }
}
