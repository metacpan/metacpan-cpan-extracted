#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'FCGI::IIS' );
}

diag( "Testing FCGI::IIS $FCGI::IIS::VERSION, Perl $], $^X" );
