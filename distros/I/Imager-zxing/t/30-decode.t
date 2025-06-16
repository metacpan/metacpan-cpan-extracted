#!perl
use strict;
use warnings;
use version;

use Test::More;

use Imager::zxing;

my $v = version->new(Imager::zxing->version);

my $d = Imager::zxing::Decoder->new;
my $im = Imager->new(file => "t/simple.ppm")
  or die "Cannot load t/simple.ppm: ", Imager->errstr;

my ($p1, $p8);
if ($Imager::formats{png}) {
  $p1 = Imager->new(file => 't/code39-FA158826-1bit.png')
    or die "Cannot load t/code39-FA158826-1bit.png: ", Imager->errstr;
  $p8 = Imager->new(file => 't/code39-FA158826-8bit.png')
    or die "Cannot load t/code39-FA158826-8bit.png: ", Imager->errstr;
}

{
  my @r = $d->decode($im);
  ok(@r, "got results");
  is($r[0]->text, "Imager::zxing", "got expected result");
  ok($r[0]->is_valid, "result is valid");
  ok($r[0]->isValid, "result is valid");
  is($r[0]->format, "DataMatrix", "format expected");
  is($r[0]->content_type, "Text", "content_type expected");
  is($r[0]->contentType, "Text", "content_type expected");
  is($r[0]->orientation, 0, "orientation expected");
  ok(!$r[0]->is_mirrored, "check is_mirrored");
  ok(!$r[0]->isMirrored, "check isMirrored");
  ok(!$r[0]->is_inverted, "check is_inverted");
  ok(!$r[0]->isInverted, "check isInverted");
  my @pos = $r[0]->position;
  # slightly different results from 2.2.0
  my $expect_pos = $v >= v2.2.0
    ? [ 34, 34, 289, 34, 289, 289, 34, 289 ]
    : [ 34, 34, 290, 34, 290, 290, 34, 290 ];
  is_deeply(\@pos, $expect_pos, "position expected")
    or diag "pos @pos";
}

{
  my @formats = Imager::zxing::Decoder->availFormats;
  my @old_formats = Imager::zxing::Decoder->avail_formats;
  # mostly checking both work
  is_deeply(\@formats, \@old_formats, "availFormats vs avail_formats");
}

{
  my $fd = Imager::zxing::Decoder->new;
  note $fd->formats;
  my @formats = split /\|/, $fd->formats;
  ok(grep($_ eq "DataMatrix", @formats),
     "should have DataMatrix by default");
  my @other = grep $_ ne "DataMatrix",
    Imager::zxing::Decoder->availFormats;
  my $other = join ",", @other; # we also accept ,
  my $otherp = join "|", @other;
  ok($fd->setFormats($other), "set formats (comma sep)");
  is($fd->formats, $otherp, "comes back as | separated");
  my @r = $fd->decode($im);
  is(@r, 0, "shouldn't decode DataMatrix now");
  ok($fd->set_formats("DataMatrix"), "set by old method name"); # old name
  is_deeply([ $fd->formats ], [ "DataMatrix" ],
            "check it was set");
}

{
  my $rim = $im->rotate(degrees => 20);
  my @r = $d->decode($rim);
  ok(@r, "got result from rotated image");
  is($r[0]->orientation, 20, "check orientation");

  {
    my $d2 = Imager::zxing::Decoder->new;
    $d2->setIsPure(1);
    @r = $d2->decode($rim);
    {
      local $TODO = "pure doesn't seem to matter";
      ok(!@r, "no result on pure decode of a rotated image");
    }
    ok($d2->isPure(), "check isPure stored");
    $d2->set_pure(0);
    ok(!$d2->isPure(), "check old set_pure worked");
  }
}

{
  my $mim = $im->copy->flip(dir => "h");
  my @r = $d->decode($mim);
  ok(@r, "got result from mirrored image");
  ok($r[0]->is_mirrored, "check is_mirrored");
  ok($r[0]->isMirrored, "check isMirrored");
}

{
  my $gim = $im->convert(preset => "grey");
  is($gim->getchannels, 1, "yes, it's grey");
  my @r = $d->decode($gim);
  ok(@r, "got result from grey image");
  is($r[0]->text, "Imager::zxing", "got expected result");
}

SKIP:
{
  $v >= v2.0.0
    or skip "inverted from 2.0.0 only", 4;
  my $inverted = $im->filter(type => "hardinvert");
  my @r = $d->decode($inverted);
  ok(@r, "got result from inverted image");
  is($r[0]->text, "Imager::zxing", "got expected result");
  local $TODO = "DataMatrix doesn't seem to set isInverted?";
  ok($r[0]->isInverted, "check is isInverted");
  ok($r[0]->is_inverted, "check is is_inverted");
}

SKIP:
{
  skip "PNG files not available", 1
    unless $p1 && $p8;
  skip "decoding these images can assert before 2.1.0", 1
    if $v < v2.1.0;
  {
    my @r = $d->decode($p8);
    ok(@r, "decoded 8-bit image");
    is($r[0]->text, "FA158826", "got expected result");
  }
  {
    my @r = $d->decode($p1);
    ok(@r, "decoded 1-bit image");
    is($r[0]->text, "FA158826", "got expected result");
  }
}

{
  # hints accessors
  my $h = Imager::zxing::Decoder->new;
  # boolean options
  my @bool_opt = qw(tryHarder tryDownscale isPure tryCode39ExtendedMode
                validateCode39CheckSum validateITFCheckSum
                returnCodabarStartEnd returnErrors tryRotate);
  if ($v >= v2.0.0) {
    push @bool_opt, "tryInvert";
  }
 BOOLOPT:
  for my $o (@bool_opt) {
    my $set_meth = "set\u$o";
    $h->$set_meth(1);
    ok($h->$o(), "$set_meth true saved");
    $h->$set_meth(0);
    ok(!$h->$o(), "$set_meth false saved");
  }
}

done_testing();
