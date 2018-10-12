# This is a test for module Image::CairoSVG.

use warnings;
use strict;
use Test::More;
use Cairo;
use Image::CairoSVG;
use FindBin '$Bin';
use File::Compare;

my $cairosvg = Image::CairoSVG->new ();
ok ($cairosvg, "Got return value from new");

my $surface = Cairo::ImageSurface->create ('argb32', 400, 400);
my $cairosvg2 = Image::CairoSVG->new (
    surface => $surface,
);
ok ($cairosvg2, "Got return value from new");

# Test getting a surface from a scalar.

my $svg = '';
my $f = "$Bin/Church.svg";
open my $in, "<:encoding(utf8)", $f or die $!;
while (<$in>) {
    $svg .= $_;
}
close $in or die $!;
my $surface_from_scalar = $cairosvg2->render ($svg);
ok ($surface_from_scalar, "got a surface from a scalar");
ok ($surface_from_scalar eq $surface, "Did not create a new surface");
my $fs = "$Bin/from-scalar.png";
$surface_from_scalar->write_to_png ($fs);

{
    my $warning;
    my $cr = 'who shot JR';
    $SIG{__WARN__} = sub { $warning = "@_"; };
    my $dabutta = Image::CairoSVG->new (
	surface => $surface,
	context => $cr,
    );
    ok ($warning, "Got a warning from both context and surface specified");
    like ($warning, qr/ignored/, "The warning looks right");
    $SIG{__WARN__} = undef;
}

for my $f (qw/Technical_college Church/) {

    # Test creating an image on a specified surface, making sure that
    # the return value from render is the specified surface.

    my $surface3 = Cairo::ImageSurface->create ('argb32', 400, 400);
    my $cairosvg3 = Image::CairoSVG->new (
	surface => $surface3,
    );
    my $stem = "$Bin/$f";
    my $file = "$stem.svg";
    ok (-f $file, "Input file $file exists (trivial test)");
    my $tempout = "$stem-out.png";
    if (-f $tempout) {
	unlink $tempout or die "Can't remove $tempout: $!";
    }
    my $surfback = $cairosvg3->render ($file);
    ok ($surfback eq $surface3, "Did not create a new surface");
    $surface3->write_to_png ($tempout);
    ok (-f $tempout, "Got file $tempout");

    # Test creating an image without a surface and writing a PNG from
    # it.

    my $cairosvg4 = Image::CairoSVG->new ();
    my $surface4 = $cairosvg4->render ($file);
    my $nosurf = "$stem-nosurf.png";
    $surface4->write_to_png ($nosurf);
    ok (-f $nosurf, "Got file from no surface specified case");
};

ok (compare ($fs, "$Bin/church-out.png"), "Church renderings equal");

done_testing ();

# Local variables:
# mode: perl
# End:
