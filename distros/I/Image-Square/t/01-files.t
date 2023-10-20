#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 4;

use Image::Square;

my $image = Image::Square->new('t/CoventryCathedral.png');

ok ($image, 'Instantiation');

ok (ref $image eq 'Image::Square', 'Correct image type');

my $square = $image->square(100);

ok ($square, 'Square image');

ok (ref $square eq 'GD::Image', 'Correct image type');

done_testing;



