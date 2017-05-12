# vi:fdm=marker fdl=0 syntax=perl:

BEGIN { use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, "C") }

use strict;
use Test;

plan tests => 9;

use Math::Units::PhysicalValue;

# A typical jump
my $exit  = new Math::Units::PhysicalValue "    10,000 ft    ";
my $open  = "3500 ft";
my $delay = "43 s";

my $dist  = $exit - $open;
my $rate  = $dist / $delay;

# my weight, unfortunately
my $weight = "180 lbs";
my $momentum = ($weight * ( ($exit - $open) / $delay )) + "0 kg*m/s";

ok( "$dist",     "6,500 ft"        ); # You shouldn't really have to convert these to strings, 
ok( "$rate",     "151.16 ft/s"     ); # perl realizes then $rdate is an obj and "151..." is a string...
ok( "$momentum", "3,761.82 kg*m/s" ); 

ok( $exit == "10000.000 ft" );
ok( $exit > $open );
ok( $exit < "20,000 ft" );

ok( $rate <= "130 miles/hour" );
ok( $rate >= "100 miles/hour" );

$Math::Units::PhysicalValue::PrintPrecision = 1;  # this helps with roundoff... since 103.07 is 151.17 instead of 151.16 ...

ok( $rate eq "103.07 miles/hour"); 

# This is a bit slower than I actually fall.
# My protrac registers the opening a bit low, 
# since it waits for a nice full canopy.

