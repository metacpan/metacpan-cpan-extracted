#!perl
use strict;
use warnings;
use version;

use Test::More;

use Imager::zxing;

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
  is($r[0]->format, "DataMatrix", "format expected");
  is($r[0]->content_type, "Text", "content_type expected");
  is($r[0]->orientation, 0, "orientation expected");
  ok(!$r[0]->is_mirrored, "check is_mirrored");
  ok(!$r[0]->is_inverted, "check is_inverted");
  my @pos = $r[0]->position;
  is_deeply(\@pos, [ 34, 34, 290, 34, 290, 290, 34, 290 ], "position expected")
    or diag "pos @pos";
}

{
  my $rim = $im->rotate(degrees => 20);
  my @r = $d->decode($rim);
  ok(@r, "got result from rotated image");
  is($r[0]->orientation, 20, "check orientation");

  {
    local $TODO = "pure doesn't seem to matter";
    my $d2 = Imager::zxing::Decoder->new;
    $d2->set_pure(1);
    @r = $d2->decode($rim);
    ok(!@r, "no result on pure decode of a rotated image");
  }
}

{
  my $mim = $im->copy->flip(dir => "h");
  my @r = $d->decode($mim);
  ok(@r, "got result from mirrored image");
  ok($r[0]->is_mirrored, "check is_mirrored");
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
  skip "PNG files not available", 1
    unless $p1 && $p8;
  my $v = version->new(Imager::zxing->version);
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

done_testing();
