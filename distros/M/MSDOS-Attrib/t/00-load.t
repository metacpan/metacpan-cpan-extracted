#! /usr/bin/perl
#---------------------------------------------------------------------
# 00-load.t
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
use_ok( 'MSDOS::Attrib' );
}

diag( "Testing MSDOS::Attrib $MSDOS::Attrib::VERSION" );
