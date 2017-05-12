################################################################################
#
#  $Revision: 4 $
#  $Author: mhx $
#  $Date: 2009/10/02 22:35:04 +0200 $
#
################################################################################
# 
# Copyright (c) 2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

use Test::More tests => 49;
use File::Spec;
use File::Copy;
use Encode qw(encode decode);
use Data::Dumper;
use utf8;

BEGIN { use_ok('MP4::File') }

my $file = "test.m4a";
my $copy = "copy.m4a";

unlink $copy if -f $copy;

my $mp4 = MP4::File->new;

ok($mp4->Read($file), "Read($file)");

checkmeta($mp4, {
  Name => 'Sine Wave',
  Artist => 'CoolEditPro',
  Writer => undef,
  Comment => undef,
  Tool => 'Nero AAC codec / Aug  6 2007',
  Year => '2008',
  Album => 'Test Signals',
  Genre => 'Noise',
  Grouping => undef,
  CoverArtCount => 1,
  CoverArt => '',
  Tempo => undef,
  Compilation => undef,
  Track => [1, 0],
  Disk => [0, 0],
});

my $tid = $mp4->FindTrackId(0);

cmp_ok($tid, '!=', 0, "FindTrackId");

cmp_ok(abs($mp4->GetTrackDuration($tid) - 0.227), '<', 0.001, "GetTrackDuration");;

is($mp4->GetTrackBitRate($tid), 11682, "GetTrackBitRate");;

is($mp4->GetTrackTimeScale($tid), 44100, "GetTrackTimeScale");;

ok($mp4->Close, "Close");

copy($file, $copy);

ok(-f $copy, "copy file");

ok($mp4->Modify($copy), "Modify($copy)");

ok($mp4->DeleteMetadataDisk, "DeleteMetadataDisk");

ok($mp4->DeleteMetadataCoverArt, "DeleteMetadataCoverArt");

setmeta($mp4, {
  Name => '我能吞下玻璃而不伤身体',
  Comment => 'Testing MP4::File',
  Genre => 'Heavy Noise',
  Track => [1, 1],
});

ok($mp4->Close, "Close");

ok(MP4::File->Optimize($copy), "Optimize");
cmp_ok(-s $copy, '<', -s $file, "size of optimized file");

ok($mp4->Read($copy), "Read");

checkmeta($mp4, {
  Name => '我能吞下玻璃而不伤身体',
  Artist => 'CoolEditPro',
  Writer => undef,
  Comment => 'Testing MP4::File',
  Tool => 'Nero AAC codec / Aug  6 2007',
  Year => '2008',
  Album => 'Test Signals',
  Genre => 'Heavy Noise',
  Grouping => undef,
  CoverArtCount => 0,
  CoverArt => undef,
  Tempo => undef,
  Compilation => undef,
  Track => [1, 1],
  Disk => [],
});

sub setmeta
{
  my($mp4, $meta) = @_;

  for my $m (sort keys %$meta) {
    my $meth = "SetMetadata$m";
    if (ref $meta->{$m}) {
      ok($mp4->$meth(@{$meta->{$m}}), $meth);
    }
    else {
      ok($mp4->$meth($meta->{$m}), $meth);
    }
  }
}

sub checkmeta
{
  my($mp4, $meta) = @_;

  for my $m (sort keys %$meta) {
    my $meth = "GetMetadata$m";
    if (ref $meta->{$m}) {
      my $v = [$mp4->$meth];
      is_deeply($v, $meta->{$m}, $meth);
    }
    else {
      my $v = $mp4->$meth;
      is($v, $meta->{$m}, $meth);
    }
  }
}
