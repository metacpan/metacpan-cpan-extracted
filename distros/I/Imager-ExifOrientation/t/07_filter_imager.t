use t::Utils want_jpeg => 1;
use Test::More tests => 162;

use Imager;
use Imager::Filter::ExifOrientation;
use Image::ExifTool 'ImageInfo';

for my $i (1..8) {
    my $img = Imager->new;
    $img->read( file => path_to("$i.jpg") ) or die $img->errstr;
    $img->filter( type => 'exif_orientation' ) or die $img->errstr;
    is_rotated($i, $img);
}

{
    # there is no exif because it's bmp
    my $img = Imager->new;
    $img->read( file => path_to("base.bmp") ) or die $img->errstr;
    $img->filter( type => 'exif_orientation' ) or die $img->errstr;
    is_rotated(1, $img); # horizonal
}

