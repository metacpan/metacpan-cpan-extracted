#!perl -T

use Test::More tests => 1;

BEGIN {
        use_ok( 'Getopt::Fancy' );
}

diag( "Testing Getopt::Fancy $Getopt::Fancy::VERSION, Perl $], $^X" );
