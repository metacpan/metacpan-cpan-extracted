#!/usr/bin/perl

use Lingua::Numending;
use Test::More tests => 1;

use Lingua::Numending qw(cyr_units);
$num = cyr_units(200, "рублей рубль рубля");
is( $num, '200 рублей',   'Return name can be "200 рублей"' );
