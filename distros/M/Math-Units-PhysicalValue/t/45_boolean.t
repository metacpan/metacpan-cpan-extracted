# vi:fdm=marker fdl=0 syntax=perl:

BEGIN { use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, "C") }

use strict;
use Test;

plan tests => 2;

use Math::Units::PhysicalValue qw(PV);

TEST1: {
    my $mass_0  = PV "0 g";
    my $mass_10 = PV "10 g";

    if( $mass_0 ) {
        ok( 0 );

    } else {
        ok( 1 );

    }

    if( $mass_10 ) {
        ok( 1 );

    } else {
        ok( 0 );

    }
}
