# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Image-SubImageFind.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('Image::SubImageFind', qw/:CONST/) };
use Cwd qw(abs_path);
use File::Basename;

#########################

my $image_dir = dirname(abs_path($0)) . "/images";

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my ($x, $y);

my $find1 = new Image::SubImageFind("$image_dir/Source.png", "$image_dir/GreenBaseline.png");
($x, $y) = $find1->GetCoordinates();
ok(($x == 83 and $y == 115), 'Find Green Baseline');

my $find2 = new Image::SubImageFind("$image_dir/Source.png", "$image_dir/RedBaseline.png");
($x, $y) = $find2->GetCoordinates();
ok(($x == 207 and $y == 115), 'Find Red Baseline');

my $find3 = new Image::SubImageFind("$image_dir/Source.png");
($x, $y) = $find3->GetCoordinates("$image_dir/DeltaBaseline.png");
ok(($x == 237 and $y == 121), 'Find Delta Baseline');

my $find4 = new Image::SubImageFind("$image_dir/Source.png", "$image_dir/GreenBaseline.png", CM_GPC);
$find4->SetMaxDelta(0); # Tighten up the search, don't allow any difference
($x, $y) = $find4->GetCoordinates();
ok(($x == 83 and $y == 115), 'Find Green Baseline (using GPC)');
