use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use Image::PNG::Libpng ':all';
BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

if (! libpng_supports ('GET_PALETTE_MAX')) {
    plan skip_all => 'Your libpng does not support get_palette_max';
}

my $file_name = "$Bin/tantei-san.png";
my $png = read_png_file ($file_name);
TODO: {
    local $TODO = 'Work out why this returns zero';
    cmp_ok ($png->get_palette_max (), '==', 256, "get_palette_max OK");
};
done_testing ();

# Local Variables:
# mode: perl
# End:
