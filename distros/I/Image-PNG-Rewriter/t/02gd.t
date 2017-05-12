use strict;
use warnings;
use Test::More;
use Image::PNG::Rewriter;

eval "use GD";
plan ($@ ? (skip_all => "GD required for testing") : (tests => 2));

my $w = int(1+rand(511));
my $h = int(1+rand(511));
my $gd = GD::Image->new($w, $h, 1);
$gd->saveAlpha(1);
$gd->interlaced(undef);
$gd->alphaBlending(0);

for my $x (0 .. $w) {
  for my $y (0 .. $w) {
    my ($r, $g, $b) = map { int(rand(256)) } 1..3;
    my $color = $gd->colorAllocateAlpha($r, $g, $b, int(rand(128)));
    $gd->setPixel($x, $y, $color);
  }
}

my $gd_png = $gd->png;

open my $f, '<', \$gd_png;

my $re = Image::PNG::Rewriter->new(handle => $f);
$re->refilter((0) x $h);
my @random_filters = map { int(rand(5)) } 1 .. $h;
$re->refilter(@random_filters);
my $re_png = $re->as_png;

{
  GD->import('GD_CMP_IMAGE');
  my $gd2 = GD::Image->newFromPngData($re_png, 1);
  ok(!($gd->compare($gd2) & GD::GD_CMP_IMAGE()));
}

open my $f2, '<', \$re_png;
my $re2 = Image::PNG::Rewriter->new(handle => $f2);
is_deeply(\@random_filters, [$re2->original_filters]);
