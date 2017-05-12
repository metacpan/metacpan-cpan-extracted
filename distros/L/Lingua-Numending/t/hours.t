#!/usr/bin/perl

use Lingua::Numending;
use Test::More tests => 1;

use Lingua::Numending qw(cyr_units);
$num = cyr_units(72, "часов час часа");
is( $num, '72 часа',   'Return name can be "72 часа"' );
