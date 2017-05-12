# vi:fdm=marker fdl=0 syntax=perl:

BEGIN { use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, "C") }

use strict;
use Test;

plan tests => 8;

use Math::Units::PhysicalValue qw(PV);

push @Math::Units::PhysicalValue::AUTO_PLURALS, [ unit => "units" ];

TEST1: {
    my $unit_12 = PV "12 units";
    my $unit_1  = PV "1  unit";
    my $unit_11 = PV "11 units";
    my $unit_5  = PV  "5 unit";

    my $u = $unit_12 - $unit_11;
    my $v = $unit_12 - $unit_5;
    my $w = $unit_1 + $unit_1;
    my $x = $unit_1 * 2;

    ok( $unit_12, "12 units" );
    ok( $unit_1,  "1 unit" );
    ok( $u,       "1 unit" );
    ok( $v,       "7 units" );
    ok( $w,       "2 units" );
    ok( $x,       "2 units" );

    ok( "$w",     "2 units" );
    ok( "$x",     "2 units" );
}
