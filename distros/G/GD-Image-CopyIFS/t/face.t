#!/usr/bin/perl
use strict;
use warnings;
use Test;
use Cwd;
use File::Spec;

BEGIN {plan tests => 8};

my $cwd = getcwd;
my $tdir = File::Spec->catdir($cwd, 't');

use GD::Image::CopyIFS;

my $width = 64;
my $height = 60;
my $scale = 4;
my $neww = $scale * $width;
my $newh = $scale * $height;
my $lena = File::Spec->catfile($tdir, 'lena.jpeg');
ok( -f $lena);

my $src_img = GD::Image->newFromJpeg($lena, 1);
ok $src_img->isa('GD::Image');
my @opts = ($src_img, 0, 0, 110, 120,
            $neww, $newh, $width, $height);

my $ifs_img = GD::Image->new($neww, $newh, 1);
ok $ifs_img->isa('GD::Image');
$ifs_img->copyIFS(@opts);
my $face_ifs = File::Spec->catfile($tdir, 'face_ifs.jpeg');
write_jpeg($ifs_img, $face_ifs);

my $resized_img = GD::Image->new($neww, $newh, 1);
ok $resized_img->isa('GD::Image');
$resized_img->copyResized(@opts);
my $face_resized = File::Spec->catfile($tdir, 'face_resized.jpeg');
write_jpeg($resized_img, $face_resized);

my $resampled_img = GD::Image->new($neww, $newh, 1);
ok $resampled_img->isa('GD::Image');
$resampled_img->copyResampled(@opts);
my $face_resampled = File::Spec->catfile($tdir, 'face_resampled.jpeg');
write_jpeg($resampled_img, $face_resampled);

sub write_jpeg {
  my ($im, $file) = @_;
  open(my $fh, '>', $file) or die "Cannot open $file: $!";
  binmode $fh;
  print $fh $im->jpeg;
  close $fh;
  
  ok( -s $file > 0);
}
