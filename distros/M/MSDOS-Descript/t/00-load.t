#! /usr/bin/perl
#---------------------------------------------------------------------
# 00-load.t
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
use_ok( 'MSDOS::Descript' );
}

diag( "Testing MSDOS::Descript $MSDOS::Descript::VERSION" );
