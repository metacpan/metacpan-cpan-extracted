#!/home/ben/software/install/bin/perl

# This CGI script prints a PNG in a random colour.

use warnings;
use strict;
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';
my $png = create_write_struct ();
my $size = 100;
$png->set_IHDR ({height => $size, width => $size, bit_depth => 8,
		 color_type => PNG_COLOR_TYPE_RGB});
my $bytes = pack "CCC", randcol (), randcol (), randcol ();
my @rows = ($bytes x $size) x $size;
$png->set_rows (\@rows);
my $img = $png->write_to_scalar ();
binmode STDOUT;
print "Content-Type:image/png\r\n\r\n$img";
exit;
sub randcol
{
    return int (rand () * 0x100);
}
