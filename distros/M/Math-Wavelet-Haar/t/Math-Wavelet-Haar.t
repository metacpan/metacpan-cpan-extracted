# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Wavelet-Haar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('Math::Wavelet::Haar',":all") };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @test = qw(1 2 3 4 5 6 7 8);
my $result = [transform1D(@test)];
my $expected = [36, -16, -4, -4, -1, -1, -1, -1];
is_deeply($result, $expected, "Haar 1D 1");

@test = qw(1 1 1 1 1 1 1 1);
$result = [transform1D(@test)];
$expected = [8, 0, 0, 0, 0, 0, 0, 0];
is_deeply($result, $expected, "Haar 1D 2");

@test = ([0,1,2,3],[1,2,3,4],[2,3,4,5],[3,4,5,6]);
$expected = [[48,-16,-4,-4],[-16,0,0,0],[-4,0,0,0],[-4,0,0,0]];
$result = [transform2D(@test)];
is_deeply($result, $expected, "Haar 2D 1");

@test = ([0,1,0,1],[1,0,1,0],[0,1,0,1],[1,0,1,0]);
$expected = [[8,0,0,0],[0,0,0,0],[0,0,-2,-2],[0,0,-2,-2]];
$result = [transform2D(@test)];
is_deeply($result, $expected, "Haar 2D 2");


@test = (36, -16, -4, -4, -1, -1, -1, -1);
$result = [detransform1D(@test)];
$expected = [1,2,3,4,5,6,7,8];
is_deeply($result, $expected, "deHaar 1D 1");

@test = qw(8 0 0 0 0 0 0 0);
$result = [detransform1D(@test)];
$expected = [1, 1, 1, 1, 1, 1, 1, 1];
is_deeply($result, $expected, "deHaar 1D 2");

@test = ([48,-16,-4,-4],[-16,0,0,0],[-4,0,0,0],[-4,0,0,0]);
$expected = [[0,1,2,3],[1,2,3,4],[2,3,4,5],[3,4,5,6]];
$result = [detransform2D(@test)];
is_deeply($result, $expected, "deHaar 2D 1");

@test = ([8,0,0,0],[0,0,0,0],[0,0,-2,-2],[0,0,-2,-2]);
$expected = [[0,1,0,1],[1,0,1,0],[0,1,0,1],[1,0,1,0]];
$result = [detransform2D(@test)];
is_deeply($result, $expected, "deHaar 2D 2");
#test for bug in 2d transforms

$expected = [[8,0,0,0],[0,0,0,0],[0,0,-2,-2],[0,0,-2,-2]];
is_deeply(\@test,$expected, "deepcloning bug");
