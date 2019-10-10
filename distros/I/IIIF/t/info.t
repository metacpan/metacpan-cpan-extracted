use strict;
use Test::More 0.98;
use IIIF::Magick qw(info);

plan skip_all => "ImageMagick missing" unless IIIF::Magick::available();

is_deeply info('t/img/67352ccc-d1b0-11e1-89ae-279075081939.png'), {
   '@context' => "http://iiif.io/api/image/3/context.json",
   protocol => "http://iiif.io/api/image",
   type => 'ImageService3',
   height => 1000,
   width => 1000
}, 'IIIF::Magick::info';

done_testing;
