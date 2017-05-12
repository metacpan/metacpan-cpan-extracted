use t::Utils want_jpeg => 0;
use Test::More tests => 144*2;

use Imager;
use Imager::Filter::ExifOrientation;
use Image::ExifTool 'ImageInfo';

for my $i (1..8) {
    my $img = Imager->new;
    $img->read( file => path_to("base.bmp") );
    $img->filter( type => 'exif_orientation', orientation => $i ) or die $img->errstr;
    is_rotated($i, $img);
}


for my $i (1..8) {
    my $img = Imager->new;
    $img->read( file => path_to("base.bmp") );
    $img->filter( type => 'exif_orientation', orientation => $i ) or die $img->errstr;
    is_rotated($i, $img);
}
