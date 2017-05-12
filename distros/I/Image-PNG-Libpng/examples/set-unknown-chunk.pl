#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::PNG::Const ':all';
use Image::PNG::Libpng ':all';
my $png = create_write_struct ();
my $size = 100;
$png->set_IHDR ({height => $size, width => $size, bit_depth => 8,
		 color_type => PNG_COLOR_TYPE_RGB});
my @rows = (pack ("CCC", 0, 0, 0) x $size) x $size;
$png->set_rows (\@rows);
my @private_chunks = ({
    name => 'prIV',
    data => 'My private Idaho',
});
#$png->set_keep_unknown_chunks (PNG_HANDLE_CHUNK_IF_SAFE );
$png->set_unknown_chunks (\@private_chunks);


#$png->set_unknown_chunk_location(PNG_AFTER_IDAT);
$png->write_png_file ('chunky.png');
exit;
sub randcol
{
    return int (rand () * 0x100);
}

