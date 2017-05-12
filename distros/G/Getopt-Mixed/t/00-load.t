#! /usr/bin/perl
#---------------------------------------------------------------------
# 00-load.t
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
use_ok( 'Getopt::Mixed' );
}

diag( "Testing Getopt::Mixed $Getopt::Mixed::VERSION" );
