#!/usr/bin/perl

use Lingua::Numending;
use Test::More tests => 1;

use Lingua::Numending qw(cyr_units);
$num = cyr_units(5, "рисунков рисунок рисунка");
is( $num, '5 рисунков',   'Return name can be "5 рисунков"' );
