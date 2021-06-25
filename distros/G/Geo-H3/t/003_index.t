#! --perl--
use strict;
use warnings;
use Test::Number::Delta;
use Test::More tests => 38;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 38 unless $lib;
  
  require_ok 'Geo::H3::Index';

  {
    #geoToH3 -r 10 --lat 38.780276 --lon -77.386706
    #8a2aaaa2e747fff

    #h3ToGeo --index 8a2aaaa2e747fff
    #38.7808807598 -77.3865869231

    #h3ToComponents -v --index 8a2aaaa2e747fff
    #╔════════════╗
    #║ H3Index    ║ 8a2aaaa2e747fff
    #╠════════════╣
    #║ Mode       ║ Hexagon (1)
    #║ Resolution ║ 10
    #║ Base Cell  ║ 21
    #║  1 Child   ║ 2
    #║  2 Child   ║ 5
    #║  3 Child   ║ 2
    #║  4 Child   ║ 5
    #║  5 Child   ║ 0
    #║  6 Child   ║ 5
    #║  7 Child   ║ 6
    #║  8 Child   ║ 3
    #║  9 Child   ║ 5
    #║ 10 Child   ║ 0
    #╚════════════╝

    my $index  = 622247346431098879;
    my $string = '8a2aaaa2e747fff';
    my $h3     = Geo::H3::Index->new(index=>$index);
    isa_ok($h3, 'Geo::H3::Index');
    can_ok($h3, 'new');
    can_ok($h3, 'index');
    can_ok($h3, 'string');
    can_ok($h3, 'geo');
    can_ok($h3, 'resolution');
    can_ok($h3, 'geoBoundary');
    is($h3->index, $index, 'index');
    is($h3->string, $string, 'string');
    is($h3->resolution, 10, 'resolution');
    isa_ok($h3->geo, 'Geo::H3::Geo', 'geo');
    delta_within($h3->geo->lat, 38.7808807598,  1e-10, '$h3->geo->lat');
    delta_within($h3->geo->lon, -77.3865869231, 1e-10, '$h3->geo->lon');
    is($h3->baseCell, 21, 'baseCell');
    ok($h3->isValid, 'isValid');
    ok(!$h3->isResClassIII, 'isResClassIII');
    ok($h3->parent->isResClassIII, 'isResClassIII');
    ok($h3->centerChild->isResClassIII, 'isResClassIII');
    ok(!$h3->isPentagon, 'isPentagon');
    is($h3->maxFaceCount, 2, 'maxFaceCount');
    delta_within($h3->area, 14577.4268473998, 1e-10, 'area');
    is($h3->areaApprox, 15047.5, 'areaApprox');
    {
      local $TODO = "Fix exactEdgeLengthM in Geo::H3::FFI";
      is($h3->edgeLength, 99999, 'edgeLength');
    }
    is($h3->edgeLengthApprox, 65.90780749, 'edgeLengthApprox ');
  }
  {
    #h3ToComponents -v --index 821c07fffffffff
    #╔════════════╗
    #║ H3Index    ║ 821c07fffffffff
    #╠════════════╣
    #║ Mode       ║ Hexagon (1)
    #║ Resolution ║ 2
    #║ Base Cell  ║ 14
    #║  1 Child   ║ 0
    #║  2 Child   ║ 0
    #╚════════════╝

    my $index  = 585961082523222015;
    my $string = '821c07fffffffff';
    my $h3     = Geo::H3::Index->new(index=>$index);
    isa_ok($h3, 'Geo::H3::Index');
    my $gb     = $h3->geoBoundary;
    isa_ok($gb, 'Geo::H3::GeoBoundary');
    is($gb->gb->num_verts, 5, 'num_verts');
    my $coordinates = $gb->coordinates;
    isa_ok($coordinates, 'ARRAY');
    is(scalar(@$coordinates), 6, 'polygon verts');
    is($h3->index, $index, 'index');
    is($h3->string, $string, 'string');
    is($h3->resolution, 2, 'resolution');
    is($h3->parent->resolution, 1, 'resolution');
    is($h3->centerChild->resolution, 3, 'resolution');
    ok($h3->isPentagon, 'isPentagon');
    ok($h3->parent->isPentagon, 'isPentagon');
    ok($h3->centerChild->isPentagon, 'isPentagon');
  }
}
