#!perl
use strict;
use warnings;
use Imager::File::APNG;
use Test::More;
use Imager::Test qw(is_image test_image test_image_gray test_image_16);

use constant PI => 3.14159265358979;

# simple
{
  my @ims;
  my $r = 40;
  for my $theta_index (0 .. 7) {
    my $im = Imager->new(xsize => 100, ysize => 100);
    my $theta = $theta_index * (PI / 4) + PI / 6;
    my $rcos = $r * cos($theta);
    my $rsin = $r * sin($theta);
    $im->line(x1 => 50 + $rcos, y1 => 50 + $rsin,
              x2 => 50 - $rcos, y2 => 50 - $rsin,
              aa => 1, color => "#FF0", endp => 1);
    push @ims, $im;
  }
  my $data;
  ok(Imager->write_multi({
    data => \$data,
    type => "apng",
    apng_delay => 0.5,
  }, @ims),
     "write APNG")
    or diag(Imager->errstr);
  -d "testout" or mkdir "testout";
  open my $fh, ">", "testout/myfirstapng.png"
    or die;
  binmode $fh;
  print $fh $data;
  close $fh;

  {
    my @inims = Imager->read_multi(type => "apng", data => $data);
    is(@inims, @ims, "read back as many as we wrote");
    is_image($inims[2], $ims[2], "compare one of them");
    is(0+$inims[2]->tags(name => "apng_delay"), 0.5, "check delay tag set");
  }
}

# mix RGB and grey
{
  my $im1 = test_image;
  my $im2 = test_image_gray;
  my $data;
  ok(Imager->write_multi({ type => "apng", data => \$data }, $im1, $im2),
     "write mixed RGB and gray")
    or diag(Imager->errstr);
  my @im = Imager->read_multi(type => "apng", data => $data)
    or diag(Imager->errstr);
  is(@im, 2, "read both back");
  is($im[1]->getchannels, 3, "second image is now RGB");
  my $im2cmp = $im2->convert(preset => "rgb");
  is_image($im[1], $im2cmp, "check it is the RGB we expect");
}

# mix RGB and RGBA
{
  my $im1 = test_image;
  my $im2 = $im1->convert(preset => "addalpha");
  my $data;
  ok(Imager->write_multi({ type => "apng", data => \$data }, $im1, $im2),
     "write mixed RGB and RGBA")
    or diag(Imager->errstr);
  my @im = Imager->read_multi(type => "apng", data => $data)
    or diag(Imager->errstr);
  is(@im, 2, "read both back");
  is($im[0]->getchannels, 4, "second image is now RGBA");
  is_image($im[0], $im2, "check it is the RGBA we expect");
}

# 8-bit gray and 16-bit RGBA
{
  my $im1 = test_image_gray;
  my $im2 = test_image_16()->convert(preset => "addalpha");
  is($im2->bits, 16, "make sure we're still 16-bit");
  my $data;
  ok(Imager->write_multi({ type => "apng", data => \$data }, $im1, $im2),
     "write mixed gray and RGBA 16-bit")
    or diag(Imager->errstr);
  my @im = Imager->read_multi(type => "apng", data => $data)
    or diag(Imager->errstr);
  is(@im, 2, "read both back");
  my $im1cmp = $im1->convert(preset => "rgb")->convert(preset => "addalpha")->to_rgb16;
  is($im[0]->bits, 16, "written as 16-bit");
  is_image($im[0], $im1cmp, "check the contents");
}

# hidden first frame
{
  my $im1 = test_image;
  $im1->settag(name => "apng_hidden", value => 1);
  my $im2 = test_image;
  my $im3 = test_image;
  my $data;
  ok(Imager->write_multi({ type => "apng", data => \$data }, $im1, $im2, $im3),
     "write with hidden first image")
    or diag(Imager->errstr);
  my @im = Imager->read_multi(type => "apng", data => $data)
    or diag(Imager->errstr);
  is($im[0]->tags(name => "apng_hidden"), 1, "check apng_hidden round tripped");
}

# tag testing
{
  my $im1 = test_image()->scale(scalefactor => 2.0);
  $im1->settag(name => "apng_delay", value => 0.5);
  my $im2 = test_image();
  $im2->settag(name => "apng_delay", value => 0.25);
  $im2->settag(name => "apng_xoffset", value => 10);
  $im2->settag(name => "apng_yoffset", value => 5);
  ok($im2->settag(name => "apng_dispose", value => "background"),
     "set dispose to background");
  ok($im2->settag(name => "apng_blend", value => "over"),
     "set blend to over");
  my $data;
  ok(Imager->write_multi({ type => "apng", data => \$data }, $im1, $im2),
     "write with canvas and offset second image")
    or diag(Imager->errstr);
  my @im = Imager->read_multi(type => "apng", data => $data)
    or diag(Imager->errstr);
  is(@im, 2, "read both back");
}

# tag errors
{
  my @tests =
    ( # tag name, tag value, qr/error/, name
      [ "apng_xoffset", -1, qr/APNG: apng_xoffset must be non-negative for page/, "neg xoffset" ],
      [ "apng_yoffset", -2, qr/APNG: apng_yoffset must be non-negative for page/, "neg yoffset" ],
      [ "apng_xoffset", 1, qr/APNG: Page 1 \(150x150\@1x0\) is outside the canvas defined by page 0 \(150x150\)/, "x overflow" ],
      [ "apng_yoffset", 2, qr/APNG: Page 1 \(150x150\@0x2\) is outside the canvas defined by page 0 \(150x150\)/, "y overflow" ],
      [ "apng_delay", -3, qr/APNG: apng_delay value -3 page 1 must be non-negative/, "neg delay" ],
      [ "apng_delay_num", -4, qr/APNG: apng_delay_num value -4 page 1 out of range 0 .. 65535/, "neg delay_num" ],
      [ "apng_delay_den", -5, qr/APNG: apng_delay_den value -5 page 1 out of range 0 .. 65535/, "neg delay_den" ],
      [ "apng_dispose", "xx", qr/APNG: unknown value 'xx' page 1 for apng_dispose/, "bad apng_dispose string" ],
      [ "apng_blend", "yy", qr/APNG: unknown value 'yy' page 1 for apng_blend/, "bad apng_blend string" ],
     );
  my $im1 = test_image;
  my $im3 = test_image;
  for my $test (@tests) {
    my ($tag, $value, $check, $name) = @$test;

    my $im2 = test_image;
    ok($im2->settag(name => $tag, value => $value), "$name: set tag");
    my $data;
    Imager->_set_error("");
    ok(!Imager->write_multi({ type => "apng", data => \$data }, $im1, $im2, $im3),
       "$name: should fail to write");
    like(Imager->errstr, $check, "$name: check message");
  }
}

# paletted image
{
  my $im1 = test_image;
  my $im2 = test_image()->to_paletted;

  my $data;
  ok(Imager->write_multi({ type => "apng", data => \$data }, $im1, $im2),
     "write with canvas and offset second image")
    or diag(Imager->errstr);
  my @im = Imager->read_multi(type => "apng", data => $data)
    or diag(Imager->errstr);
  is(@im, 2, "read both back");
}

done_testing();
