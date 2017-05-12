# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-Intersection-Line.t'

#########################

use Test::More tests => 12;
use Math::Intersection::StraightLine;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $finder = Math::Intersection::StraightLine->new();
my $vector_a = [[20,60],[-40,0]];
my $vector_b = [[50,80],[0,50]];
my $result = $finder->vectors($vector_a,$vector_b);
ok(ref($finder) eq 'Math::Intersection::StraightLine','Object created');
ok($result->[0] == 50 && $result->[1] == 60,'Vectors with one intersection point');

$vector_a = [[20,60],[30,10]];
$vector_b = [[50,80],[50,75]];
$result = $finder->point_limited($vector_a,$vector_b);
ok($result == 0,'Lines (defined limits) with no intersection point');

$vector_a = [[20,60],[60,60]];
$vector_b = [[50,80],[50,5]];
$result = $finder->point_limited($vector_a,$vector_b);
ok($result->[0] == 50 && $result->[1] == 60,'Lines (defined limits) with one intersection point');

$vector_a = [[20,60],[20,10]];
$vector_b = [[50,80],[50,5]];
$result = $finder->point_limited($vector_a,$vector_b);
ok($result == 0,'parallel lines(vertical)');

$vector_a = [[20,60],[20,10]];
$vector_b = [[50,80],[20,10]];
$result = $finder->vectors($vector_a,$vector_b);
ok($result == 0,'parallel vectors(diagonal)');

$vector_a = [[20,60],[30,10]];
$vector_b = [[50,80],[60,30]];
$result = $finder->point_limited($vector_a,$vector_b);
ok($result == 0,'parallel lines(diagonal)');

$vector_a = [[20,60],[20,10]];
$vector_b = [[60,80],[20,10]];
$result = $finder->vectors($vector_a,$vector_b);
ok($result == -1,'overlapping vectors');

$vector_a = [[20,60],[30,10]];
$vector_b = [[50,80],[50,75]];
$result = $finder->points($vector_a,$vector_b);
ok($result->[0] == 50 && $result->[1] == -90,'Lines with one intersection point');

# test y=9x+5 and y=-3x-2
my $function_one = [9,5];
my $function_two = [-3,-2];
$result = $finder->functions($function_one,$function_two);
ok($result->[1] == -0.25,'Lines with one intersection point');

$vector_a = [[93,197],[385,231]];
$vector_b = [[129,374],['129','57']];
$result = $finder->point_limited($vector_a,$vector_b);
ok($result->[0] == 129,'Lines with one intersection point');