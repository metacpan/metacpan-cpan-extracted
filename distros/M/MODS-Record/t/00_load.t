#!perl -Tw

use strict;

use Test::More tests=>1;

BEGIN {
    use_ok( 'MODS::Record' );
}

diag( "Testing MODS::Record $MODS::Record::VERSION" );
