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

{
  my $im = Imager->new;
  ok($im->read(file => "testimg/exif.heic"),
     "read image with EXIF metadata");
  # this metadata was copied from an old, old file with exiftool
  my %expect =
    (
      exif_aperture => "2.97085",
      exif_artist => "Tony Cook",
      exif_color_space => "1",
      exif_color_space_name => "sRGB",
      exif_date_time => "2005:12:06 15:25:39",
      exif_date_time_digitized => "2005:12:06 15:25:39",
      exif_date_time_original => "2005:11:25 00:00:00",
      exif_exposure_mode => "0",
      exif_exposure_mode_name => "Auto exposure",
      exif_exposure_time => "0.0166667",
      exif_f_number => "2.8",
      exif_flashpix_version => "0100",
      exif_image_description => "Imager Development Notes",
      exif_iso_speed_ratings => "100",
      exif_make => "Canon",
      exif_model => "CanoScan LiDE 35",
      exif_resolution_unit => "2",
      exif_resolution_unit_name => "inches",
      exif_scene_capture_type => "0",
      exif_scene_capture_type_name => "Standard",
      exif_shutter_speed => "5.90689",
      exif_software => "CanoScan Toolbox 4.5",
      exif_user_comment => "ASCII   Part of notes from reworking i_arc() and friends.",
      exif_version => "0221",
      exif_white_balance => "0",
      exif_white_balance_name => "Auto white balance",
      exif_x_resolution => "75",
      exif_y_resolution => "75",
     );
  for my $tag (keys %expect) {
    is($im->tags(name => $tag), $expect{$tag}, $tag);
  }
}

done_testing();
