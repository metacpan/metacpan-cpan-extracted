#!perl -w
use strict;
use Test::More;

use Imager::File::HEIF;
use Imager::Test qw(test_image is_image_similar);
use lib 't/lib';

{
  my $cmp = test_image;

  my $im = Imager->new;
  ok($im->read(file => "testimg/simple.heic", type => "heif"),
     "read single image");
  is($im->getwidth, $cmp->getwidth, "check width");
  is($im->getheight, $cmp->getheight, "check height");
  is_image_similar($im, $cmp, 10_000_000, "check if vaguely similar");
}

SKIP:
{
  my $cmp = Imager->new(xsize => 64, ysize => 64, channels => 4);
  $cmp->box(filled => 1, color => [ 255, 0, 0, 128 ], xmax => 31);
  $cmp->box(filled => 1, color => [ 0, 0, 255, 192 ], xmin => 32);
  $cmp->box(filled => 1, ymin => 50, color => [ 0, 255, 0, 64 ]);

  my $im = Imager->new;
  ok($im->read(file => "testimg/alpha.heic", type => "heif"),
     "read an alpha image")
    or do {
      diag $im->errstr;
      skip("couldn't read alpha image", 1);
    };
  is($im->getwidth, $cmp->getwidth, "check width");
  is($im->getheight, $cmp->getheight, "check height");
  is($im->getchannels, $cmp->getchannels, "check channels");
  is_image_similar($im, $cmp, 1_000_000, "check if vaguely similar");
}

done_testing();
