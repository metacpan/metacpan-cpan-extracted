use strict;
use warnings;
use Test::More tests => 14;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 14 unless $lib;

  require_ok 'Geo::H3::FFI';

  my $obj = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  #$ geoToH3 --lat 40.689167 --lon -74.044444 --resolution 10
  #8a2a1072b59ffff
  #
  #$ h3ToComponents -v -i 8a2a1072b59ffff
  #╔════════════╗
  #║ H3Index    ║ 8a2a1072b59ffff
  #╠════════════╣
  #║ Mode       ║ Hexagon (1)
  #║ Resolution ║ 10
  #║ Base Cell  ║ 21
  #║  1 Child   ║ 0
  #║  2 Child   ║ 2
  #║  3 Child   ║ 0
  #║  4 Child   ║ 3
  #║  5 Child   ║ 4
  #║  6 Child   ║ 5
  #║  7 Child   ║ 3
  #║  8 Child   ║ 2
  #║  9 Child   ║ 6
  #║ 10 Child   ║ 3
  #╚════════════╝

  my $lat        = 40.689167;
  my $lon        = -74.044444;
  my $index      = 622236750694711295;
  my $resolution = 10;
  my $parent     = '617733151067471871';
  my $basecell   = 21;

  diag(sprintf('Index: %x', $index));

  my $h3GetResolution = $obj->h3GetResolution($index);
  is($h3GetResolution, $resolution, 'h3GetResolution');
  
  my $h3GetBaseCell   = $obj->h3GetBaseCell($index);
  is($h3GetBaseCell, $basecell, 'h3GetBaseCell');

  my $h3IsValid   = $obj->h3IsValid($index);
  ok($h3IsValid, 'h3IsValid');

  my $xh3IsResClassIII   = $obj->h3IsResClassIII($index);
  ok(!$xh3IsResClassIII, 'h3IsResClassIII');

  my $h3IsResClassIII   = $obj->h3IsResClassIII($parent);
  ok($h3IsResClassIII, 'h3IsResClassIII');

  my $h3IsPentagon   = $obj->h3IsPentagon($index);
  ok(!$h3IsPentagon, 'h3IsPentagon');

  my $maxFaceCount   = $obj->maxFaceCount($index);
  is($maxFaceCount, 2, 'maxFaceCount');

  my @array = (-1,-1,-1,-1,-1);
  my $h3GetFaces     = $obj->h3GetFaces($index, \@array);
  is($array[0], 2, 'h3GetFacesWrapper');
  is($array[1], -1, 'h3GetFacesWrapper');

  my $aref = $obj->h3GetFacesWrapper($index);
  isa_ok($aref, 'ARRAY');
  is(scalar(@$aref), 1, 'h3GetFacesWrapper size');
  is($aref->[0], 2, 'h3GetFacesWrapper');
}
