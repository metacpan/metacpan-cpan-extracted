# This is a test for module Image::PNG::Cairo.

use warnings;
use strict;
use Test::More;
use Cairo;
use Image::PNG::Libpng;
use Image::PNG::Cairo 'cairo_to_png';

my $surface = Cairo::ImageSurface->create ('argb32', 100, 100);
my $cr = Cairo::Context->create ($surface);
$cr->set_source_rgb (1.0, 0.0, 0.0);
$cr->rectangle (0, 0, 100, 100);
$cr->fill ();
my $png = cairo_to_png ($surface);

ok ($png, "Got PNG");

# Check the colour really is red to make sure that the transforms
# worked OK.

my $out = 'red-100x100.png';

$png->write_png_file ($out);

# Tidy up file.

if (-f $out) {
    unlink $out;
}

# error test

eval {
cairo_to_png ({});
};
ok ($@, "got error with cairo_to_png ({})");
like ($@, qr/Cairo::ImageSurface/);

done_testing ();

# Local variables:
# mode: perl
# End:
