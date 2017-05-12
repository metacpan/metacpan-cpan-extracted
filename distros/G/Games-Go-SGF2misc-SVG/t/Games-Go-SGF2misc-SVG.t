# vi: syntax=perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Go-SGF2misc-SVG.t'

#########################

use Test;
BEGIN { plan tests => 4 };
use Games::Go::SGF2misc::SVG;
ok(1); # If we made it this far, we're ok.

$image = Games::Go::SGF2misc::SVG->new('imagesize'=>'5in','boardsize' => 5);

$image->drawGoban();

$image->placeStone('b',[1,1]);
$image->placeStone('w',[2,2]);
$image->placeStone('b',[3,3]);
$image->addCircle([1,1]);
$image->addLetter([2,2],'249');
$image->addLetter([3,3],'X');
ok(2);

$image->export('image.png');
if (-e 'image.png') {
    ok(3);
    unlink('image.png');
} else {
    nok(3);
}

$image->save('image.svg');
if (-e 'image.svg') {
    ok(4);
    unlink('image.svg');
} else {
    nok(4);
}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

