#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::Script;

use_ok( 'Devel::Leak::Module' );

script_compiles(
	'script/perlbloat',
	'Main script compiles',
);
