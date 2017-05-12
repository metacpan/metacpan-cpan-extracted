#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Fauxtobox' );
}

diag( "Testing Fauxtobox $Fauxtobox::VERSION, Perl $], $^X" );
