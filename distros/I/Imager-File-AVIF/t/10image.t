#!perl
use strict;
use warnings;
use Imager;
use Imager::File::AVIF;
use Test::More;
use Imager::Test qw(test_image is_image_similar is_image);

Imager::File::AVIF->can_read()
  or plan skip_all => "No read codecs available";

Imager::File::AVIF->can_write()
  or plan skip_all => "No write codecs available";

-d "testout" or mkdir "testout", 0755
  or die "Cannot mkdir testout: $!";

{
  my $im = test_image;
  my $data;
  ok($im->write(data => \$data, type => "avif"),
     "write single");
  my $im2 = Imager->new;
  ok($im2->read(data => \$data, type => "avif"),
     "read it back");
  is_image_similar($im2, $im, 50_000, "check image roughly matches");
}

{
  my $im = test_image;
  my $data;
  ok($im->write(data => \$data, type => "avif", avif_lossless => 1),
     "write single lossless");
  my $im2 = Imager->new;
  ok($im2->read(data => \$data, type => "avif"),
     "read lossless back");
  is_image($im2, $im, "check lossless image matches");
}

{
  # multiple
  my $im = test_image;
  $im->settag(name => "avif_timescale", value => 61);
  $im->settag(name => "avif_duration", value => 2);
  my $im2 = $im->copy->flip(dir => "h");
  # this should be ignored
  $im2->settag(name => "avif_timescale", value => 70);
  $im2->settag(name => "avif_duration", value => 3);
  my $data;
  ok(Imager->write_multi({data => \$data, type => "avif"}, $im, $im2),
     "write multiple");
  ok(Imager->write_multi({file => "test.avif", type => "avif"}, $im, $im2),
     "write multiple");
  my @result = Imager->read_multi(data => $data, type => "avif")
    or diag(Imager->errstr);
  is(@result, 2, "got two images");
  is_image_similar($result[0], $im, 50_000, "check first image roughly matches");
  is_image_similar($result[1], $im2, 50_000, "check second image roughly matches");
  is($result[0]->tags(name => "avif_timescale"), 61, "61Hz timescale from first image");
  is($result[1]->tags(name => "avif_timescale"), 61, "61Hz timescale from second image");
  is($result[0]->tags(name => "avif_duration"),   2, "2 tick duration from first image");
  is($result[1]->tags(name => "avif_duration"),   3, "3 tick duration from second image");

  my $one = Imager->new;
  ok($one->read(data => $data, type => "avif", page => 1), "directly get second page");

  is_image_similar($one, $im2, 50_000, "check picked second image roughly matches");
}

done_testing();
