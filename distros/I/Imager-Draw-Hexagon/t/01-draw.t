use strict;
use Imager;
use lib '../lib';
use Test::More;
use Test::Deep;
use_ok 'Imager::Draw::Hexagon';


my $image = Imager->new(xsize => 500, ysize => 500);

my $hex = Imager::Draw::Hexagon->new(image => $image, side_length => 100, x => 100, y => 50);

cmp_deeply(
    $hex->ew_coords,
    [ [ 100, 136 ], [ 150, 50 ], [ 250, 50 ], [ 300, 136 ], [ 250, 223 ], [ 150, 223 ] ],
    'east-west coords'
);

cmp_deeply(
    $hex->ns_coords,
    [ [ 100, 100 ], [ 186, 50 ], [ 273, 100 ], [ 273, 200 ], [ 186, 250 ], [ 100, 200 ] ],
    'north-south coords'
);

$hex->draw(color => 'green', direction => 'ns');
$hex->y(250);
$hex->outline(color => 'blue');


if (grep {'png' eq $_} Imager->write_types) {
    $image->write(file => '/tmp/hex.png');
    diag 'test image written to /tmp/hex.png';
}

done_testing();
