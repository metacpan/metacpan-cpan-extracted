#!/usr/bin/perl

use 5.006;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;

use_ok( 'Devel::Eval' );
