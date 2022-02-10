#! --perl--
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::Number::Delta;
use Test::More tests => 38;
use FFI::CheckLib qw{find_lib};
my $lib = find_lib(lib=>'h3');

SKIP: {
  skip 'libh3 not available', 38 unless $lib;
  
  require_ok 'Geo::H3::Index';

  {
    #h3ToComponents -v --index 844c001ffffffff
    #╔════════════╗
    #║ H3Index    ║ 844c001ffffffff
    #╠════════════╣
    #║ Mode       ║ Hexagon (1)
    #║ Resolution ║ 4
    #║ Base Cell  ║ 38
    #║  1 Child   ║ 0
    #║  2 Child   ║ 0
    #║  3 Child   ║ 0
    #║  4 Child   ║ 0
    #╚════════════╝

    my $index  = 595812165542215679;
    my $string = '844c001ffffffff';
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
    is($h3->resolution, 4, 'resolution');
    ok($h3->isPentagon, 'isPentagon');
    ok($h3->parent->isPentagon, 'isPentagon');
    ok($h3->centerChild->isPentagon, 'isPentagon');
    {
      my $ring = $h3->kRing;
      isa_ok($ring, 'ARRAY');
      is(scalar(@$ring), 6);
      ok(grep {$_->string eq '844c001ffffffff'} @$ring); #center
      ok(grep {$_->string eq '844c005ffffffff'} @$ring);
      ok(grep {$_->string eq '844c007ffffffff'} @$ring);
      ok(grep {$_->string eq '844c009ffffffff'} @$ring);
      ok(grep {$_->string eq '844c00bffffffff'} @$ring);
      ok(grep {$_->string eq '844c00dffffffff'} @$ring);
    }
    {
      my $ring = $h3->kRing(2);
      isa_ok($ring, 'ARRAY');
      is(scalar(@$ring), 16);
      ok(grep {$_->string eq '844c001ffffffff'} @$ring); #center
      ok(grep {$_->string eq '844c005ffffffff'} @$ring); #1
      ok(grep {$_->string eq '844c007ffffffff'} @$ring); #1
      ok(grep {$_->string eq '844c009ffffffff'} @$ring); #1
      ok(grep {$_->string eq '844c00bffffffff'} @$ring); #1
      ok(grep {$_->string eq '844c00dffffffff'} @$ring); #1
      ok(grep {$_->string eq '844c06bffffffff'} @$ring); #2
      ok(grep {$_->string eq '844c047ffffffff'} @$ring); #2
      ok(grep {$_->string eq '844c043ffffffff'} @$ring); #2
      ok(grep {$_->string eq '844c055ffffffff'} @$ring); #2
      ok(grep {$_->string eq '844c057ffffffff'} @$ring); #2
      ok(grep {$_->string eq '844c039ffffffff'} @$ring); #2
      ok(grep {$_->string eq '844c03dffffffff'} @$ring); #2
      ok(grep {$_->string eq '844c02bffffffff'} @$ring); #2
      ok(grep {$_->string eq '844c029ffffffff'} @$ring); #2
      ok(grep {$_->string eq '844c063ffffffff'} @$ring); #2
    }
  }
}
