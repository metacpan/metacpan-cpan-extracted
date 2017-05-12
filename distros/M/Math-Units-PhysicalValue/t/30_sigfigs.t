# vi:fdm=marker fdl=0 syntax=perl:

BEGIN { use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, "C") }

use strict;
use Test;

plan tests => 1;

use Math::Units::PhysicalValue "PV";

# This is NOT the sigfig support that's on the todo list...

TEST1: {
    my $sun = PV "864,938 miles";

    ok( $sun->sci( 3 ), "8.65e5 miles" );
}
