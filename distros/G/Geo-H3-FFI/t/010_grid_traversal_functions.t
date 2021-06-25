use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::Number::Delta;
use Test::More tests => 43;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 43 unless $lib;

  require_ok 'Geo::H3::FFI';

  my $obj = Geo::H3::FFI->new;
  isa_ok($obj, 'Geo::H3::FFI');

  #$ geoToH3 --lat 40.689167 --lon -74.044444 --resolution 10
  #8a2a1072b59ffff

  my $index      = 622236750694711295;   #8a2a1072b59ffff
  my $resolution = 10;
  is(sprintf("%x", $index ), '8a2a1072b59ffff', 'index' );
  #kRing
  {
    my $k    = 0;
    my $size = 1;
    my $aref = $obj->kRingWrapper($index, $k);
    isa_ok($aref, 'ARRAY');
    is(scalar(@$aref), $size, 'size');
    is($obj->maxKringSize($k), $size, 'maxKringSize');
    is($aref->[0], $index, 'index in kRing'); #by defintion K=0 is the index itself
  }

  {
    my $k    = 1;
    my $size = 7;
    my $aref = $obj->kRingWrapper($index, $k);
    isa_ok($aref, 'ARRAY');
    is(scalar(@$aref), $size, 'size');
    is($obj->maxKringSize($k), $size, 'maxKringSize');
  }

  {
    my $k    = 2;
    my $size = 19;
    my $aref = $obj->kRingWrapper($index, $k);
    isa_ok($aref, 'ARRAY');
    is(scalar(@$aref), $size, 'size');
    is($obj->maxKringSize($k), $size, 'maxKringSize');
    is((grep {$_ ==  $index} @$aref)[0], $index, 'index in kRing');
  }
  #maxKringSize
  #max supported K-ring distance limited to 17
  is($obj->maxKringSize(17), 919, 'maxKringSize');

  #kRingDistances
  #$ffi->attach(kRingDistances => ['uint64_t', 'int', 'uint64_aref_919', 'int_aref_919'] => 'void' => \&_oowrapper);

  {
    my $k    = 2;
    my $size = 19;
    my $href = $obj->kRingDistancesWrapper($index, $k);
    isa_ok($href, 'HASH');
    is(scalar(keys %$href), 19, 'size');
    #diag Dumper $href;
  }

  #hexRange
  {
    #local $TODO = 'not sure why this does not work';
    my $k       = 1;
    my $indexes = $obj->hexRangeWrapper($index, $k);
    isa_ok($indexes, 'ARRAY');
    diag Dumper $indexes;
  }

  {
    my $k    = 0;
    my $size = 1;
    my $aref = $obj->hexRangeWrapper($index, $k);
    isa_ok($aref, 'ARRAY');
    is(scalar(@$aref), $size, 'size');
    is($obj->maxKringSize($k), $size, 'maxKringSize');
    is($aref->[0], $index, 'index in hexRange'); #by defintion K=0 is the index itself
  }

  {
    my $k    = 1;
    my $size = 7;
    my $aref = $obj->hexRangeWrapper($index, $k);
    isa_ok($aref, 'ARRAY');
    is(scalar(@$aref), $size, 'size');
    is($obj->maxKringSize($k), $size, 'maxKringSize');
    is((grep {$_ ==  $index} @$aref)[0], $index, 'index in hexRange');
  }

  {
    my $k    = 2;
    my $size = 19;
    my $aref = $obj->hexRangeWrapper($index, $k);
    isa_ok($aref, 'ARRAY');
    is(scalar(@$aref), $size, 'size');
    is($obj->maxHexRangeSize($k), $size, 'maxKringSize');
    is((grep {$_ ==  $index} @$aref)[0], $index, 'index in hexRange');
  }

  #hexRangeDistances
  {
    my $k    = 2;
    my $size = 19;
    my $href = $obj->hexRangeDistancesWrapper($index, $k);
    isa_ok($href, 'HASH');
    is(scalar(keys %$href), 19, 'size');
    diag Dumper $href;
  }

  #hexRanges
  #hexRing

  is($obj->maxHexRingSize(0),  1, 'maxHexRingSize');
  is($obj->maxHexRingSize(1),  6, 'maxHexRingSize');
  is($obj->maxHexRingSize(3), 18, 'maxHexRingSize');

  {
    my $k    = 1;
    my $size = 6;
    my $aref = $obj->hexRingWrapper($index, $k);
    isa_ok($aref, 'ARRAY');
    is(scalar(@$aref), $size, 'size');
    is($obj->maxHexRingSize($k), $size, 'maxKringSize');
  }

  #h3Line
  my $start = 622236750694711295; #0x8a2a1072b59ffff;
  my $end   = 622236750638612479; #0x8a2a1072801ffff;
  my $aref  = $obj->h3LineWrapper($start, $end);
  diag map {sprintf "%s => %s\n", $_ => $obj->h3ToStringWrapper($_)} @$aref;
  is($aref->[0], $start, 'h3LineWrapper');
  is($aref->[-1], $end, 'h3LineWrapper');
  is(scalar(@$aref), 23, 'h3LineWrapper');

  #h3LineSize
  my $size = $obj->h3LineSize($start, $end);
  is($size, 23, 'h3LineSize');

  #h3Distance
  my $dist = $obj->h3Distance($start, $end);
  is($dist, 22, 'h3Distance');

  #experimentalH3ToLocalIj
  #experimentalLocalIjToH3
}
