#!/usr/bin/perl

use Lingua::Numending;
use Test::More tests => 1;

use Lingua::Numending qw(cyr_units);
$num = cyr_units(30, "минут минута минуты");
is( $num, '30 минут',   'Return name can be "30 минут"' );
