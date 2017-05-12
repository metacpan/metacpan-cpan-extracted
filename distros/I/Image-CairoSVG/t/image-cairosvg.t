# This is a test for module Image::CairoSVG.

use warnings;
use strict;
use Test::More;
use Cairo;
use Image::CairoSVG;
use FindBin '$Bin';

my $cairosvg = Image::CairoSVG->new ();
ok ($cairosvg);

my $surface = Cairo::ImageSurface->create ('argb32', 400, 400);
my $cairosvg2 = Image::CairoSVG->new (
    surface => $surface,
);
ok ($cairosvg2);

for my $f (qw/Technical_college Church/) {
    my $surface = Cairo::ImageSurface->create ('argb32', 400, 400);
    my $cairosvg2 = Image::CairoSVG->new (
	surface => $surface,
    );
    my $stem = "$Bin/$f";
    my $file = "$stem.svg";
    $cairosvg2->render ($file);
    my $tempout = "$stem-out.png";
    $surface->write_to_png ($tempout);
    ok (-f $tempout);
};

done_testing ();

# Local variables:
# mode: perl
# End:
