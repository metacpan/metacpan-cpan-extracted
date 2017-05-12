use strict;
use warnings;
use Test::More;

use Image::JPEG::EstimateQuality;

# These files are saved by GIMP 2.8.6.
my @tests = (
    "t/img/q001.jpg" => 2,      # I don't know the reason
    "t/img/q002.jpg" => 2,
    "t/img/q003.jpg" => 3,
    "t/img/q007.jpg" => 7,
    "t/img/q010.jpg" => 10,
    "t/img/q030.jpg" => 30,
    "t/img/q049.jpg" => 49,
    "t/img/q050.jpg" => 50,
    "t/img/q051.jpg" => 51,
    "t/img/q070.jpg" => 70,
    "t/img/q080.jpg" => 80,
    "t/img/q090.jpg" => 90,
    "t/img/q099.jpg" => 99,
    "t/img/q100.jpg" => 100,
);

while (@tests) {
    my ($file, $q) = splice @tests, 0, 2;

    is jpeg_quality($file), $q, "quality = $q";
}

done_testing;
