#!perl -w
use strict;
use Test::More;
use version;

use Imager::File::HEIF;
use Imager::Test qw(test_image is_image_similar);
use lib 't/lib';

-d "testout" or mkdir "testout";
Imager->open_log(log => "testout/20write.log");

my $ver = Imager::File::HEIF->libversion();
my $over = version->new($ver);

{
  my $im = test_image;

  my $data;
  ok($im->write(data => \$data, type => "heif"),
     "write single image")
    or diag $im->errstr;
  ok(length $data, "actually wrote something");
  is(substr($data, 4, 8), 'ftypheic', "got a HEIC file");

  my $res = Imager->new;
  ok($res->read(data => \$data, type => "heif"),
     "read it back in again")
    or diag $res->errstr;
  is($res->getwidth, $im->getwidth, "check width");
  is($res->getheight, $im->getheight, "check height");
  is($res->getchannels, $im->getchannels, "check channels");
  is_image_similar($res, $im, 8_000_000, "check image matches roughly");

  # lossless
  my $data2;
  ok($im->write(data => \$data2, type => "heif", heif_lossless => 1),
     "write in lossless mode");
  ok(length $data2, "got some data");
  my $res2 = Imager->new;
  ok($res2->read(data => \$data2, type => "heif"),
     "read it back in")
    or diag $res2->errstr;
  is_image_similar($res, $im, 8_000_000, "check image matches roughly");
  # horribly enough, lossless is worse than lossy @80 quality
  note "quality lossy    ".Imager::i_img_diff($im->{IMG}, $res->{IMG});
  note "quality lossless ".Imager::i_img_diff($im->{IMG}, $res2->{IMG});
}

{
  my $im = test_image;
  my $im2 = $im->convert(preset => "gray")
    or diag $im->errstr;
  my $cmp = $im2;

  my $data;
  ok($im2->write(data => \$data, type => "heif"),
     "write single gray image")
    or diag $im2->errstr;
  ok(length $data, "actually wrote something (gray)");
  # prior to libheif 1.20 the main brand was incorrectly "heic"
  # but should apparently be "heix", since monochrome isn't part
  # of the base profile
  # https://github.com/strukturag/libheif/issues/1765
  like(substr($data, 4, 8), qr/^ftyphei[cx]$/, "got a HEIC file");

  my $res = Imager->new;
  ok($res->read(data => \$data, type => "heif"),
     "read it back in again")
    or diag $res->errstr;
  is($res->getwidth, $cmp->getwidth, "check width");
  is($res->getheight, $cmp->getheight, "check height");
  is($res->getchannels, $cmp->getchannels, "check channels");
  is_image_similar($res, $cmp, 1_000_000, "check image matches roughly");
}

SKIP:
{
  my $cmp = Imager->new(xsize => 64, ysize => 64, channels => 4);
  $cmp->box(filled => 1, color => [ 255, 0, 0, 128 ], xmax => 31);
  $cmp->box(filled => 1, color => [ 0, 0, 255, 192 ], xmin => 32);
  $cmp->box(filled => 1, ymin => 50, color => [ 0, 255, 0, 64 ]);
  my $data;
  ok($cmp->write(data => \$data, type => "heif"),
     "write alpha")
    or do { diag $cmp->errstr; skip "couldn't write alpha", 1; };
  my $res = Imager->new;
  ok($res->read(data => \$data, type => "heif"),
     "read it back in")
    or do { diag $res->errstr; skip "couldn't read it back in", 1; };
  is($res->getwidth, $cmp->getwidth, "check width");
  is($res->getheight, $cmp->getheight, "check height");
  is($res->getchannels, $cmp->getchannels, "check channels");
  is_image_similar($res, $cmp, 10_000, "check image matches roughly");
}

SKIP:
{ # tags
  $over >= v1.15.0
    or skip "need 1.15.0 for aspect ration", 5;
  my $im = test_image();
  my $data;
  ok($im->write(data => \$data, type => "heif",
                i_xres => 3, i_yres => 2),
     "write with resolution tags");
  my $rd = Imager->new;
  ok($rd->read(data => \$data, type => "heif"),
     "read it back");
  is($rd->tags(name => "i_xres"), 3, "i_xres right");
  is($rd->tags(name => "i_yres"), 2, "i_yres right");
  is($rd->tags(name => "i_aspect_only"), 1, "i_aspect_only set");
}

SKIP:
{
  my @cmp;
  push @cmp, test_image();
  push @cmp, test_image()->convert(preset => "gray");
  @cmp = ( (@cmp) x 3 );

  my $data;
  ok(Imager->write_multi({ type => "heif", data => \$data }, @cmp),
     "write multiple images")
    or diag(Imager->errstr);
  ok(length $data, "it wrote something");

  my @res = Imager->read_multi(type => "heif", data => \$data)
    or do { diag "couldn't read:" . Imager->errstr; skip "couldn't read", 1 };
  is(@res, @cmp, "got the right number of images");
  for my $i ( 0 .. $#cmp) {
    my $cmp = $cmp[$i];
    is_image_similar($res[$i], $cmp, 8_000_000,
                     "check image $i");
  }
}

SKIP:
{
  # look for a non-HEVC encoder
  my ($enc) = grep $_->compression ne "hevc"
    && Imager::File::HEIF->have_decoder_for($_->compression),
    Imager::File::HEIF->encoders;
  $enc or skip "only hevc available for both encode and decode", 1;
  my $cmp = test_image();
  my $data;
  note "compression format ", $enc->compression;
  ok($cmp->write(data => \$data, type => "heif",
                 heif_compression => $enc->compression),
     "write with non-HEVC compression");
  my $res = Imager->new;
  # we might not have a decoder for this, even if we have an
  # encoder... fix once we can list decoders
  ok($res->read(data => \$data, type => "heif"),
     "read it back again ".$enc->compression)
    or diag $res->errstr;
  is($res->getwidth, $cmp->getwidth, "check width");
  is($res->getheight, $cmp->getheight, "check height");
  is($res->getchannels, $cmp->getchannels, "check channels");
  # this random format might produce worse results than hevc
  is_image_similar($res, $cmp, 10_000_000, "check image matches roughly");

  $cmp = $cmp->copy;
  note "encoder ", $enc->id;
  undef $data;
  ok($cmp->write(data => \$data, type => "heif",
                 heif_encoder => $enc->id),
     "write using a specified encoder")
    or die $cmp->errstr;
  ok($res->read(data => \$data, type => "heif"),
     "read it back again");
  is($res->getwidth, $cmp->getwidth, "check width");
  is($res->getheight, $cmp->getheight, "check height");
  is($res->getchannels, $cmp->getchannels, "check channels");
  # this random format might produce worse results than hevc
  is_image_similar($res, $cmp, 10_000_000, "check image matches roughly");

  $cmp = $cmp->copy;
  ok($cmp->write(data => \$data, type => "heif",
                 heif_encoder => $enc->id,
                heif_compression => $enc->compression),
     "write using a specified encoder and compression")
    or die $cmp->errstr;
  ok($res->read(data => \$data, type => "heif"),
     "read it back again");
  is($res->getwidth, $cmp->getwidth, "check width");
  is($res->getheight, $cmp->getheight, "check height");
  is($res->getchannels, $cmp->getchannels, "check channels");
  # this random format might produce worse results than hevc
  is_image_similar($res, $cmp, 10_000_000, "check image matches roughly");

  $cmp = $cmp->copy; # strip tags
  undef $data;
  ok(!$cmp->write(data => \$data, type => "heif",
                  heif_encoder => $enc->id,
                  heif_compression => "hevc"),
     "fail to write with encoder/compression mismatch");
  like($cmp->errstr, qr/no encoder named '.*' found with compression '.*'/,
       "check message");
}
{
  # write with an undefined compression
  my $cmp = test_image;
  my $data;
  ok(!$cmp->write(data => \$data, type => "heif",
                  heif_compression => "not a compression"),
     "fail to write with bad compression");
  like($cmp->errstr, qr/Unknown heif compression 'not a compression'/,
       "check message");

  # unknown encoder
  $cmp = $cmp->copy; # strip tags
  undef $data;
  ok(!$cmp->write(data => \$data, type => "heif",
                  heif_encoder => "not an encoder"),
     "write with unknown encoder");
  like($cmp->errstr, qr/no encoder named 'not an encoder' found/,
       "check message");
}

SKIP:
{
  ok(Imager::File::HEIF->have_encoder_for("hevc"),
     "yes, we have a HEVC encoder");
  my %comp = map {$_ => 1 }
    grep $_ ne "undefined", Imager::File::HEIF->compression_names;
  for my $enc (Imager::File::HEIF->encoders) {
    delete $comp{$enc->compression};
  }
  %comp
    or skip "Amazingly, you can use all compression methods", 1;
  my ($comp) = keys %comp; # we can't compress this
  ok(!Imager::File::HEIF->have_encoder_for($comp),
     "can't encode $comp");
}

SKIP:
{
  my @enc = Imager::File::HEIF->encoders("hevc");
  $enc[0]->id eq "x265"
    or skip "need x265 to test parameters", 1;
  my $data;
  my $src = test_image();
  ok($src->write(data => \$data, type => "heif",
                 heif_chroma => "444"),
     "write with custom string parameter");

  $data = "";
  $src = $src->copy;
  ok(!$src->write(data => \$data, type => "heif",
                  heif_chroma => "bad chroma"),
     "fail to write with bad custom string parameter");

  $data = "";
  $src = $src->copy;
  ok($src->write(data => \$data, type => "heif",
                 heif_complexity => 1),
     "write with custom integer parameter")
    or diag $src->errstr;

  $data = "";
  $src = $src->copy;
  ok(!$src->write(data => \$data, type => "heif",
                  heif_complexity => 101),
     "fail to write with bad custom integer parameter");
}

done_testing();
