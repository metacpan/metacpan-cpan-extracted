use t::Utils want_jpeg => 1;
use Test::More tests => 162;

use Imager::ExifOrientation;

for my $i (1..8) {
    is_rotated($i, Imager::ExifOrientation->rotate( data => slurp(path_to("$i.jpg")) ));
}

is_rotated(1, Imager::ExifOrientation->rotate( data => slurp(path_to("base.jpg")) ));
