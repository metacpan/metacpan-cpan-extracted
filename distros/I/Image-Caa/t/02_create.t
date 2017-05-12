use Test::More tests => 11;

use Image::Caa;


#
# create objects
#

isa_ok(Image::Caa->new(), 'Image::Caa');
isa_ok(Image::Caa->new('black_bg' => 1), 'Image::Caa');
isa_ok(Image::Caa->new('black_bg' => 0), 'Image::Caa');
isa_ok(Image::Caa->new('dither' => 'DitherNone'), 'Image::Caa');
isa_ok(Image::Caa->new('dither' => 'DitherOrdered2'), 'Image::Caa');
isa_ok(Image::Caa->new('dither' => 'DitherOrdered4'), 'Image::Caa');
isa_ok(Image::Caa->new('dither' => 'DitherOrdered8'), 'Image::Caa');
isa_ok(Image::Caa->new('dither' => 'DitherRandom'), 'Image::Caa');
isa_ok(Image::Caa->new('driver' => 'DriverANSI'), 'Image::Caa');
isa_ok(Image::Caa->new('driver' => 'DriverCurses'), 'Image::Caa');
isa_ok(Image::Caa->new('driver' => 'DriverTest'), 'Image::Caa');
