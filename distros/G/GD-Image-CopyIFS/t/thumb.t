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

my $lena = File::Spec->catfile($tdir, 'lena.jpeg');
ok( -f $lena);

my $src_img = GD::Image->newFromJpeg($lena, 1);
my $scale = 1.45;
my ($sx, $sy) = $src_img->getBounds();
my ($dx, $dy) = (int($scale*$sx), int($scale*$sy));
ok $src_img->isa('GD::Image');
my ($ifs_img, $rx, $ry) = GD::Image->thumbIFS($src_img, scale => $scale);
ok $ifs_img->isa('GD::Image');
my $th_ifs = File::Spec->catfile($tdir, 'th_ifs.jpeg');
write_jpeg($ifs_img, $th_ifs);

my @opts = ($src_img, 0, 0, 0, 0, $dx, $dy, $sx, $sy);

my $resized_img = GD::Image->new($dx, $dy, 1);
ok $resized_img->isa('GD::Image');
$resized_img->copyResized(@opts);
my $th_resized = File::Spec->catfile($tdir, 'th_resized.jpeg');
write_jpeg($resized_img, $th_resized);

my $resampled_img = GD::Image->new($dx, $dy, 1);
ok $resampled_img->isa('GD::Image');
$resampled_img->copyResampled(@opts);
my $th_resampled = File::Spec->catfile($tdir, 'th_resampled.jpeg');
write_jpeg($resampled_img, $th_resampled);

sub write_jpeg {
  my ($im, $file) = @_;
  open(my $fh, '>', $file) or die "Cannot open $file: $!";
  binmode $fh;
  print $fh $im->jpeg;
  close $fh;
  
  ok( -s $file > 0);
}
