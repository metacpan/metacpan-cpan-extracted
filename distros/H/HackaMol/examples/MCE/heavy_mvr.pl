#!/usr/bin/env perl
# repetitive calculation of the average vector length for a sphere 
# of random vectors shows capabilities of using MCE to use multiple cores.
use Modern::Perl;
use Math::Vector::Real;
use Math::Vector::Real::Random;
use MCE::Map; #carry out the map using the many core engine
use Time::HiRes qw(time);

my $t1   = time;
my @avg  = mce_map { 
                 my @mvrs = &gen_mvr_sphere;
                 my $sum = 0;
                 $sum += abs($_) foreach @mvrs;
                 $sum/(scalar(@mvrs)) 
               } 0 .. 1000;

say foreach @avg;

my $t2 = time;

printf ("time: %10.4f \n", $t2-$t1);

sub gen_mvr_sphere {
  return (map {Math::Vector::Real->random_in_sphere( 3, 40.0 )} 1 .. 8953) ;
}

