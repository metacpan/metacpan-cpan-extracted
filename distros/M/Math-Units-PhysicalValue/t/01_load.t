# vi:fdm=marker fdl=0 syntax=perl:

BEGIN { use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, "C") }

use strict;
use Test;

plan tests => 2;

use Math::Units::PhysicalValue qw(PV); ok 1;

my $v = PV("8 miles");

$v = deunit $v;

ok( $v, 8 );
