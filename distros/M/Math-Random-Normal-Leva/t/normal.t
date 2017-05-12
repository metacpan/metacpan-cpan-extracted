use strict;
use warnings;
use Test::More;
use Test::Deep;
use Math::Random::Normal::Leva qw(random_normal);
use Statistics::Descriptive;

my @normal = map { random_normal } 1 .. 100000;

my $stat = Statistics::Descriptive::Full->new;
$stat->add_data(@normal);

cmp_deeply(
    $stat,
    methods(
        mean     => num(0, 0.02),
        variance => num(1, 0.02),
        skewness => num(0, 0.02),
        kurtosis => num(0, 0.1),
        mode     => num(0, 0.02),
        median   => num(0, 0.02),
    ),
);

done_testing;
