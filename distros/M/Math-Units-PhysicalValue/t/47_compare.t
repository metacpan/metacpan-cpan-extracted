# vi:fdm=marker fdl=0 syntax=perl:

BEGIN { use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, "C") }

use strict;
use Test;

plan tests => 6;

use Math::Units::PhysicalValue qw(PV);

TEST1: {
    my $mass_12 = PV "12 g";
    my $mass_15 = PV "15 g";

    ok( $mass_12<=>$mass_15, 3 <=> 4 );
    ok( $mass_15<=>$mass_12, 3 <=> 2 );
    ok( $mass_15<=>$mass_15, 3 <=> 3 );

    ok( $mass_12 cmp $mass_15, "12 g" cmp "15 g" );
    ok( $mass_15 cmp $mass_12, "15 g" cmp "12 g" );
    ok( $mass_15 cmp $mass_15, "15 g" cmp "15 g" );
}
