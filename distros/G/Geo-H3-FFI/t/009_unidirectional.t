use strict;
use warnings;
use Test::Number::Delta;
use Test::More tests => 26;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 26 unless $lib;

  require_ok 'Geo::H3::FFI';

  my $obj = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  #$ geoToH3 --lat 40.689167 --lon -74.044444 --resolution 10
  #8a2a1072b59ffff
  #$ geoToH3 --lat 40.703468 --lon -74.016821 --resolution 10
  #8a2a1072801ffff

  my $index1     = 622236750694711295;   #8a2a1072b59ffff
  my $index2     = $obj->stringToH3Wrapper('8a2a1072801ffff');
  my $indexadj   = $obj->stringToH3Wrapper('8a2a1072b58ffff');
  my $resolution = 10;
  is(sprintf("%x", $index1  ), '8a2a1072b59ffff', 'index' );
  is(sprintf("%x", $index2  ), '8a2a1072801ffff', 'index' );
  is(sprintf("%x", $indexadj), '8a2a1072b58ffff', 'index' );

  #$ffi->attach(h3LineSize => ['uint64_t', 'uint64_t'] => 'int');
  {
    my $h3LineSize = $obj->h3LineSize($index1, $index2);
    is($h3LineSize, 23, 'h3LineSize');
  }
  {
    my $h3LineSize = $obj->h3LineSize($index1, $indexadj);
    is($h3LineSize, 2, 'h3LineSize');
  }
  
  #$ffi->attach(h3Distance => ['uint64_t', 'uint64_t'] => 'int');
  {
    my $h3Distance = $obj->h3Distance($index1, $index2);
    is($h3Distance, 22, 'h3Distance');
  }
  {
    my $h3Distance = $obj->h3Distance($index1, $indexadj);
    is($h3Distance, 1, 'h3Distance');
  }

  #$ffi->attach(maxH3ToChildrenSize => ['uint64_t', 'int'] => 'int');
  {
    my $maxH3ToChildrenSize = $obj->maxH3ToChildrenSize($index1, 9);
    is($maxH3ToChildrenSize, 0, 'maxH3ToChildrenSize');
  }
  {
    my $maxH3ToChildrenSize = $obj->maxH3ToChildrenSize($index1, 10);
    is($maxH3ToChildrenSize, 1, 'maxH3ToChildrenSize');
  }
  {
    my $maxH3ToChildrenSize = $obj->maxH3ToChildrenSize($index1, 11);
    is($maxH3ToChildrenSize, 7, 'maxH3ToChildrenSize');
  }
  {
    my $maxH3ToChildrenSize = $obj->maxH3ToChildrenSize($index1, 12);
    is($maxH3ToChildrenSize, 7*7, 'maxH3ToChildrenSize');
  }

  #$ffi->attach(h3IndexesAreNeighbors => ['uint64_t', 'uint64_t'] => 'int');
  {
    my $h3IndexesAreNeighbors = $obj->h3IndexesAreNeighbors($index1, $index2);
    is($h3IndexesAreNeighbors, 0, 'h3IndexesAreNeighbors');
  }
  {
    my $h3IndexesAreNeighbors = $obj->h3IndexesAreNeighbors($index1, $indexadj);
    is($h3IndexesAreNeighbors, 1, 'h3IndexesAreNeighbors');
  }
  
  #$ffi->attach(getH3UnidirectionalEdge => ['uint64_t', 'uint64_t'] => 'uint64_t');
  {
    my $getH3UnidirectionalEdge = $obj->getH3UnidirectionalEdge($index1, $index2);
    is($getH3UnidirectionalEdge, 0, 'getH3UnidirectionalEdge');
  }
  {
    my $getH3UnidirectionalEdge = $obj->getH3UnidirectionalEdge($index1, $indexadj);
    is($getH3UnidirectionalEdge, 1558985473187774463, 'getH3UnidirectionalEdge');
  }

  #$ffi->attach(h3UnidirectionalEdgeIsValid => ['uint64_t'] => 'int');
  my $h3UnidirectionalEdgeIsValid = $obj->h3UnidirectionalEdgeIsValid($index1);
  is($h3UnidirectionalEdgeIsValid, 0, 'h3UnidirectionalEdgeIsValid');

  #$ffi->attach(getOriginH3IndexFromUnidirectionalEdge => ['uint64_t'] => 'uint64_t');
  my $getOriginH3IndexFromUnidirectionalEdge = $obj->getOriginH3IndexFromUnidirectionalEdge($index1);
  is($getOriginH3IndexFromUnidirectionalEdge, 0, 'getOriginH3IndexFromUnidirectionalEdge');

  #$ffi->attach(getDestinationH3IndexFromUnidirectionalEdge => ['uint64_t'] => 'uint64_t');
  my $getDestinationH3IndexFromUnidirectionalEdge = $obj->getDestinationH3IndexFromUnidirectionalEdge($index1);
  is($getDestinationH3IndexFromUnidirectionalEdge, 0, 'getDestinationH3IndexFromUnidirectionalEdge');

  my $gb       = $obj->gb;
  isa_ok($gb, 'Geo::H3::FFI::Struct::GeoBoundary');
  #$ffi->attach(getH3UnidirectionalEdgeBoundary => ['uint64_t', 'geo_boundary_t'] => 'void');
  my $getH3UnidirectionalEdgeBoundary = $obj->getH3UnidirectionalEdgeBoundary($index1, $gb);
  is($getH3UnidirectionalEdgeBoundary, undef, 'getH3UnidirectionalEdgeBoundary');
  #use Data::Dumper qw{Dumper};
  #diag(Dumper({gb=>$gb}));

  isa_ok($gb, 'Geo::H3::FFI::Struct::GeoBoundary');
  can_ok($gb, 'num_verts');
  can_ok($gb, 'verts');
  is($gb->num_verts, 0, '$gb->num_verts');

  #diag(Dumper({verts=>$verts}));

  foreach my $count (1 .. $gb->num_verts) {
    my $vert = $gb->verts->[$count - 1]; #$gb->verts sizeof 10
    #diag(Dumper({vert=>$vert}));
    isa_ok($vert, 'Geo::H3::FFI::Struct::GeoCoord');
    can_ok($vert, 'lat');
    can_ok($vert, 'lon');
    #diag(sprintf("Count: %s, Lat: %s (%s), Lon: %s (%s)", $count, $vert->lat, $obj->radsToDegs($vert->lat),
    #                                                              $vert->lon, $obj->radsToDegs($vert->lon)));
  }
}
