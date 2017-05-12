use t::Utils want_jpeg => 1;
use Test::More tests => 162*2;

use Imager;
use Imager::Filter::ExifOrientation;

for my $i (1..8) {
    my $img = Imager->new;
    $img->read( file => path_to("base.jpg") );
    $img->filter( type => 'exif_orientation', data => slurp(path_to("$i.jpg")) ) or die $img->errstr;
    is_rotated($i, $img);
}

do {
    my $img = Imager->new;
    $img->read( file => path_to("base.jpg") );
    $img->filter( type => 'exif_orientation', data => slurp(path_to("base.jpg")) ) or die $img->errstr;
    is_rotated(1, $img);
};

for my $i (1..8) {
    my $img = Imager->new;
    $img->read( file => path_to("base.bmp") );
    $img->filter( type => 'exif_orientation', data => slurp(path_to("$i.jpg")) ) or die $img->errstr;
    is_rotated($i, $img);
}

do {
    my $img = Imager->new;
    $img->read( file => path_to("base.bmp") );
    $img->filter( type => 'exif_orientation', data => slurp(path_to("base.bmp")) ) or die $img->errstr;
    is_rotated(1, $img);
};
