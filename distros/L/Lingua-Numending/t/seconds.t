#!/usr/bin/perl

use Lingua::Numending;
use Test::More tests => 1;

use Lingua::Numending qw(cyr_units);
$num = cyr_units(3, "секунд секунда секунды");
is( $num, '3 секунды',   'Return name can be "3 секунды"' );
