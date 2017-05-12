#!/usr/bin/perl

use warnings;
use strict;
use lib 't/testlib';
use Test::More tests => 2;

use TestMod;    #TestMod uses MyExport

ok( eq_array( [ test1() ], [ 2, 3, 5, 7 ] ), '@bar in another module' );

is( test2(), MyExport::askme(), 'askme() in another module' );
