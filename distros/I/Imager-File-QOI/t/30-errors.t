#!perl
use strict;
use warnings;
use Test::More;
use Imager;
use Imager::Test qw(is_image test_image test_image_gray);


{
  my $im = test_image();
  my $data;
  ok(!$im->write(data => \$data, type => "qoi", qoi_colorspace => 2),
     "fail to write with bad colorspace");
  like($im->errstr, qr/qoi_colorspace must be \d+ or \d+/,
       "check error message for bad colorspace");
}

{
  my $im = test_image();
  my $data;
  ok($im->write(data => \$data, type => "qoi"),
     "write the whole image");
  # truncate it
  $data = substr($data, 0, length($data) / 2);
  my $cmp = Imager->new;
  # see https://github.com/phoboslab/qoi/issues/98
  local $::TODO = "decoder accepts incomplete images";
  ok(!$cmp->read(data => $data),
     "fail to read truncated image");
}

done_testing();
