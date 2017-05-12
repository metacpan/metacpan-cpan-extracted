#!perl -Tw

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Geometry::Formula' );
}

diag( "Testing Geometry::Formula $Geometry::Formula::VERSION" );
