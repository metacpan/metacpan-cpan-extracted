# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GD-Cairo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 4 };
use GD;
use GD::Cairo qw();
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $img = GD::Cairo->new( 5, 5 );

my $black = $img->colorAllocate(0, 0, 0);
my $white = $img->colorAllocate(255,255,255);

$img->fill(0,0,$white);
$img->setPixel(3,3,$black);
$img->setPixel(0,0,$black);

is($img->getPixel(3,3),$black,"GetPixel(3,3)");
is($img->getPixel(0,0),$black,"GetPixel(0,0)");
is($img->getPixel(1,1),$white,"GetPixel(background)");
