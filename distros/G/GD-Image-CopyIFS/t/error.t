#!/usr/bin/perl
use strict;
use warnings;
use Test;
use Cwd;
use File::Spec;

BEGIN {plan tests => 5};

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
            $neww, $newh, $width, $height, -3, 5);

my $dst_img = GD::Image->new($neww, $newh);
ok $dst_img->isa('GD::Image');
eval {$dst_img->copyIFS(@opts);};
if ($@) {
  ok($@ =~ /must be between/);
}
else {
  ok(0, 1, 'error expected');
}

@opts = ($src_img, 0, 0, 120, 120,
         $neww, $newh, $width, $height, 0.77, -3);
eval {$dst_img->copyIFS(@opts);};
if ($@) {
  ok($@ =~ /must be larger/);
}
else {
  ok(0, 1, 'error expected');
}
