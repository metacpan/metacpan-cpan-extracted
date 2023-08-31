#!perl
use strict;
use warnings;

use Test::More;

use Imager::zxing;

my $d = Imager::zxing::Decoder->new;
my $im = Imager->new(file => "t/simple.ppm")
  or die "Cannot load t/simple.ppm: ", Imager->errstr;

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

done_testing();
