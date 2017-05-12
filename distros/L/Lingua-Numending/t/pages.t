#!/usr/bin/perl

use Lingua::Numending;
use Test::More tests => 1;

use Lingua::Numending qw(cyr_units);
$num = cyr_units(20, "страниц страница страницы");
is( $num, '20 страниц',   'Return name can be "20 страниц"' );
