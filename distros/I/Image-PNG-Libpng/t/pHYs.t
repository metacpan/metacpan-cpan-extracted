use warnings;
use strict;
use FindBin '$Bin';
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';
use Test::More tests => 3;

# Test reading a background.

my $png = create_read_struct ();
open my $fh, "<:raw", "$Bin/libpng/cdun2c08.png" or die $!;
init_io ($png, $fh);
read_png ($png);
close $fh or die $!;
my $pHYs = get_pHYs ($png);
ok ($pHYs->{res_x} == 1000, "X resolution");
ok ($pHYs->{res_y} == 1000, "Y resolution");
ok ($pHYs->{unit_type} == 1, "unit type");
