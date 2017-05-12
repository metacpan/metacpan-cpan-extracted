#!/usr/bin/perl

use strict;
use Test::More tests => 1;

use Inline Perl => q[
    sub set_x { $::x = $_[0] }
    sub get_x { $::x }
];

set_x(1);
$::x = 2;
is( get_x(), 1 );
$::x = 0;
