# Test misc. functions.
use FindBin '$Bin';
use lib $Bin;
use IPNGLT;
my $png = read_png_file ("$Bin/gecko-1200-gray8.png");
is ($png->height (), 624);
is ($png->width (), 1116);
is ($png->get_channels (), 1);
is ($png->get_bit_depth (), 8);
cmp_ok ($png->get_color_type, '==', PNG_COLOR_TYPE_GRAY, "color type");
cmp_ok ($png->get_interlace_type, '==', PNG_INTERLACE_NONE, "interlace type");
done_testing ();
