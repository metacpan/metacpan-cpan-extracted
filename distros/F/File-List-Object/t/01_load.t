#!perl
use Test::More tests => 1;

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	use_ok( 'File::List::Object' ) or BAIL_OUT('Could not load File::List::Object.');
}

diag( "Testing File::List::Object $File::List::Object::VERSION" );
