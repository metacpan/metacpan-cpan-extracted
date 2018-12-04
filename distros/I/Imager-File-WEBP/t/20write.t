#!perl -w
use strict;
use Test::More;

use Imager::File::WEBP;
use Imager::Test qw(test_image is_image_similar is_image);
use lib 't/lib';
use TestImage qw(alpha_test_image);

{
  my $im = test_image;

  my $data;
  ok($im->write(data => \$data, type => "webp"),
     "write single image");
  ok(length $data, "actually wrote something");
  is(substr($data, 0, 4), 'RIFF', "got a RIFF file");
  is(substr($data, 8, 4), 'WEBP', "of WEBP flavour");
}

SKIP:
{
  my $im = test_image()->convert(preset => "gray");
  my $data;
  ok($im->write(data => \$data, type => "webp"),
     "write grayscale image")
    or skip "failed to write gray", 1;
  ok(length $data, "actually wrote something");
  my $im2 = Imager->new;
  ok($im2->read(data => \$data, type => "webp"),
     "read it back in")
    or skip "Failed to read it back", 1;
  # WEBP doesn't store grayscale
  my $check = $im->convert(preset => "rgb");
  is_image_similar($im2, $check, 200_000, "check it's similar");
}

SKIP:
{
  my $im = alpha_test_image();
  my $data;
  ok($im->write(data => \$data, type => "webp"),
     "write alpha image")
    or skip "Failed to write RGB with alpha", 1;
  my $im2 = Imager->new;
  ok($im2->read(data => \$data, type => "webp"),
     "read it back in")
    or skip "Failed to read it", 1;
  is_image_similar($im2, $im, 2_000_000, "check it's similar");
}

SKIP:
{
  my $im = alpha_test_image()->convert(preset => "gray");
  my $data;
  ok($im->write(data => \$data, type => "webp"),
     "write alpha image")
    or skip "Failed to write gray with alpha", 1;
  my $im2 = Imager->new;
  ok($im2->read(data => \$data, type => "webp"),
     "read it back in")
    or skip "Failed to read it", 1;
  my $check = $im->convert(preset => "rgb");
  is($check->getchannels, 4, "check \$check channels");
  is_image_similar($im2, $check, 2_000_000, "check it's similar");
}

SKIP:
{
  my $im = test_image();

  my $data;
  ok($im->write(data => \$data, type => "webp", webp_mode => "lossless"),
     "write noalpha lossless")
    or skip "couldn't write noalpha lossless", 1;
  my $im2 = Imager->new;
  ok($im2->read(data => \$data, type => "webp"), "read it back in")
    or skip "couldn't read it back in", 1;
  is_image($im2, $im, "lossless must match exactly");
  is($im2->tags(name => "webp_mode"), "lossless", "check webp_mode set");
}

SKIP:
{
  my $im = alpha_test_image();
  my $data;
  ok($im->write(data => \$data, type => "webp", webp_mode => "lossless"),
     "write alpha lossless")
    or skip "couldn't write alpha lossless", 1;
  my $im2 = Imager->new;
  ok($im2->read(data => \$data, type => "webp"), "read it back in")
    or skip "couldn't read it back in", 1;
  is_image($im2, $im, "lossless must match exactly");
  is($im2->tags(name => "webp_mode"), "lossless", "check webp_mode set");
}

{
  my $im = test_image();
  my $data;
  ok(!$im->write(data => \$data, type => "webp", webp_mode => "invalid"),
     "fail to write webp invalid mode");
  like($im->errstr, qr/webp_mode must be 'lossy' or 'lossless'/,
       "check error message");
  print "# ", $im->errstr, "\n";
}

SKIP:
{
  my @im = ( test_image(), test_image() );
  my $data;
  $im[0]->settag(name => "webp_left", value => 11);
  $im[0]->settag(name => "webp_top", value => 6);
  $im[1]->settag(name => "webp_left", value => 20);
  $im[1]->settag(name => "webp_top", value => 8);
  $im[0]->settag(name => "webp_loop_count", value => 50);
  $im[1]->settag(name => "webp_loop_count", value => 60);
  $im[0]->settag(name => "webp_background", value => "color(255,128,0)");
  $im[1]->settag(name => "webp_background", value => "color(255,128,255)");
  $im[0]->settag(name => "webp_duration", value => 200);
  $im[1]->settag(name => "webp_duration", value => 250);
  $im[0]->settag(name => "webp_dispose", value => "background");
  $im[1]->settag(name => "webp_dispose", value => "none");
  $im[0]->settag(name => "webp_blend", value => "none");
  $im[1]->settag(name => "webp_blend", value => "alpha");
  ok(Imager->write_multi({ data => \$data, type => "webp" }, @im),
     "write two images")
    or skip "couldn't read: " . Imager->errstr, 1;
  my @im2 = Imager->read_multi(data => \$data, type => "webp");
  is(@im2, 2, "read two images");
  is_image_similar($im2[0], $im[0], 2_000_000, "check first image");
  is_image_similar($im2[1], $im[1], 2_000_000, "check second image");
  is($im2[0]->tags(name => "webp_left"), 10, "first image webp_left");
  is($im2[0]->tags(name => "webp_top"), 6, "first image webp_top");
  is($im2[1]->tags(name => "webp_left"), 20, "second image webp_left");
  is($im2[1]->tags(name => "webp_top"), 8, "second image webp_top");
  is($im2[0]->tags(name => "webp_duration"), 200, "first image webp_duration");
  is($im2[1]->tags(name => "webp_duration"), 250, "second image webp_duration");
  is($im2[0]->tags(name => "webp_dispose"), "background", "first image webp_dispose");
  is($im2[1]->tags(name => "webp_dispose"), "none", "second image webp_dispose");
  is($im2[0]->tags(name => "webp_blend"), "none", "first image webp_blend");
  is($im2[1]->tags(name => "webp_blend"), "alpha", "second image webp_blend");

  # only the first image matters for animation parameters
  is($im2[0]->tags(name => "webp_loop_count"), 50, "first image webp_loop_count");
  is($im2[1]->tags(name => "webp_loop_count"), 50, "second image webp_loop_count");
  is($im2[0]->tags(name => "webp_background"), "color(255,128,0,255)", "first image webp_background");
  is($im2[1]->tags(name => "webp_background"), "color(255,128,0,255)", "first image webp_background");
}

{
  my @im = ( test_image(), test_image() );
  $im[1]->settag(name => "webp_mode", value => "invalid");
  my $data;
  ok(!Imager->write_multi({ data => \$data, type => "webp" }, @im),
     "write multiple with bad tag in second");
  like(Imager->errstr, qr/webp_mode must be 'lossy' or 'lossless'/,
       "check error message");
}

{
  my $im = test_image();
  my $data;
  ok($im->write(data => \$data, type => "webp", webp_quality => 100),
     "write with quality 100");
  my $im100 = Imager->new;
  ok($im100->read(data => \$data), "read it back");
  $data = '';
  ok($im->write(data => \$data, type => "webp", webp_quality => 70),
     "write with quality 70");
  my $im70 = Imager->new;
  ok($im70->read(data => \$data), "read it back");
  my $im70err = Imager::i_img_diff($im70->{IMG}, $im->{IMG});
  my $im100err = Imager::i_img_diff($im100->{IMG}, $im->{IMG});
  cmp_ok($im100err, '<', $im70err, "check 100 quality is 'better'");
}

{
  my $im = test_image();
  my $data;
  ok(!$im->write(data => \$data, type => "webp", webp_quality => 101),
     "fail to write with quality 101");
  like($im->errstr, qr/webp_quality must be in the range 0 to 100 inclusive/,
       "check message");
}

{
  my $im = test_image();
  my $data;
  ok(!Imager->write_multi({ data => \$data, type => "webp", webp_dispose => "bad"}, $im, $im),
     "fail to write with webp_dispose bad");
  is(Imager->errstr, "invalid webp_dispose, must be 'none' or 'background'",
     "check message");
}
{
  my $im = test_image();
  my $data;
  ok(!Imager->write_multi({ data => \$data, type => "webp", webp_blend => "bad"}, $im, $im),
     "fail to write with webp_blend bad");
  is(Imager->errstr, "invalid webp_blend, must be 'none' or 'alpha'",
     "check message");
}

done_testing();
