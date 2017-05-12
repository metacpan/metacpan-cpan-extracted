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

my $width = 32;
my $height = 30;
my $scale = 8;
my $neww = $scale * $width;
my $newh = $scale * $height;
my $lena = File::Spec->catfile($tdir, 'lena.jpeg');
ok( -f $lena);

my $src_img = GD::Image->newFromJpeg($lena, 1);
ok $src_img->isa('GD::Image');
my @opts = ($src_img, 0, 0, 120, 120,
            $neww, $newh, $width, $height);

my $ifs_img = GD::Image->new($neww, $newh, 1);
ok $ifs_img->isa('GD::Image');
$ifs_img->copyIFS(@opts);
my $eye_ifs = File::Spec->catfile($tdir, 'eye_ifs.jpeg');
write_jpeg($ifs_img, $eye_ifs);

my $resized_img = GD::Image->new($neww, $newh, 1);
ok $resized_img->isa('GD::Image');
$resized_img->copyResized(@opts);
my $eye_resized = File::Spec->catfile($tdir, 'eye_resized.jpeg');
write_jpeg($resized_img, $eye_resized);

my $resampled_img = GD::Image->new($neww, $newh, 1);
ok $resampled_img->isa('GD::Image');
$resampled_img->copyResampled(@opts);
my $eye_resampled = File::Spec->catfile($tdir, 'eye_resampled.jpeg');
write_jpeg($resampled_img, $eye_resampled);

sub write_jpeg {
  my ($im, $file) = @_;
  open(my $fh, '>', $file) or die "Cannot open $file: $!";
  binmode $fh;
  print $fh $im->jpeg;
  close $fh;
  ok( -s $file > 0);
}
