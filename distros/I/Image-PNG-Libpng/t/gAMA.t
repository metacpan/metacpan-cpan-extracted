#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Test::More;
use FindBin;
use Image::PNG::Libpng ':all';
my $png = read_png_file ("$FindBin::Bin/libpng/g03n2c08.png");
my $gamma = $png->get_gAMA ();
cmp_ok ($gamma - 0.35, '<', 0.0001);
my $opng = create_write_struct ();
$opng->set_IHDR ($png->get_IHDR ());
$opng->set_rows ($png->get_rows ());
$opng->set_gAMA (0.2);
my $out = "$FindBin::Bin/out-gAMA.png";
$opng->write_png_file ($out);
my $png2 = read_png_file ($out);
my $gamma2 = $png2->get_gAMA ();
cmp_ok ($gamma2 - 0.2, '<', 0.0001);
if (-f $out) {
    unlink $out;
}

done_testing ();
