#! /usr/bin/perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Iterator::RoundRobin' );
}

diag( "Testing Iterator::RoundRobin $Iterator::RoundRobin::VERSION, Perl $], $^X" );
