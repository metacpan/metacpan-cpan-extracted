#!perl
use strict;
use warnings;
use Test::More;
use Imager;
use Imager::Test qw(is_image test_image test_image_gray);

my $test_image = test_image;
my $gray_test = test_image_gray;

{
  my $data;
  ok($test_image->write(data => \$data, type => "qoi"),
     "write out test image");
  my $cmp = Imager->new;
  ok($cmp->read(data => $data),
     "read it back in");
  is_image($cmp, $test_image, "check the images match");
}

{
  my $data;
  ok($gray_test->write(data => \$data, type => "qoi"),
     "write out gray test image");
  my $result = Imager->new;
  ok($result->read(data => $data),
     "read gray test back");
  my $cmp = Imager->combine(src => [ ( $gray_test ) x 3 ],
				channels => [ ( 0 ) x 3 ])
    or diag Imager->errstr;
  is_image($result, $cmp, "check the gray matches");
}

{
  # tags
  my $data;
  my $im = test_image();
  ok($im->write(data => \$data, type => "qoi", qoi_colorspace => 1),
     "test with linear colorspace");
  my $cmp = Imager->new;
  ok($cmp->read(data => $data),
     "read it back");
  is_image($cmp, $im, "check the image matches");
  is($cmp->tags(name => "qoi_colorspace"), 1,
     "check colorspace written and returned");
  is($cmp->tags(name => "i_format"), "qoi",
     "check i_format tag");
}

done_testing();
