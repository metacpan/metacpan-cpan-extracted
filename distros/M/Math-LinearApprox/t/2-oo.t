#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Math::LinearApprox;

plan tests => 8;

my @points = ( 
        0, 4,
        2, 1,
        7, -6.5,
        );

my $la_1 = Math::LinearApprox->new();
for (my $i = 0; $i < @points; $i += 2) {
    $la_1->add_point($points[$i], $points[$i + 1]);
}
is_deeply([$la_1->equation()], [-1.5, 4], "coefficents approximation");
is_deeply($la_1->equation_str(), "y = -1.5 * x + 4", "string approximation");

my $la_2 = Math::LinearApprox->new(\@points);
is_deeply([$la_2->equation()], [-1.5, 4], "coefficents approximation");
is_deeply($la_2->equation_str(), "y = -1.5 * x + 4", "string approximation");

my $la_3 = Math::LinearApprox->new([0, 0, 1, 1]);
is_deeply([$la_3->equation()], [1, 0], "coefficents approximation");
is_deeply($la_3->equation_str(), "y = 1 * x + 0", "string approximation");

my $la_4 = Math::LinearApprox->new([0, 0, 1, 1, 2, 0]);
is_deeply([$la_4->equation()], [0, 1/3], "coefficents approximation");
is_deeply($la_4->equation_str(), "y = 0 * x + " . (1/3), "string approximation");
