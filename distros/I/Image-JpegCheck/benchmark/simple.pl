use strict;
use warnings;
use Benchmark ':all';
use Image::Size;
use Image::JpegCheck;
use Imager;

my $fname = 't/foo.jpg';

cmpthese(
    -1, {
        'image-jpegcheck' => sub {
            Image::JpegCheck::is_jpeg($fname);
        },
        'imager' => sub {
            my $img = Imager->new;
            $img->read(file => $fname);
        },
        'image-size' => sub {
            Image::Size::imgsize($fname);
        },
    }
);
