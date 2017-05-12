#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Exim::SpoolMessage' );
}

diag( "Testing Exim::SpoolMessage $Exim::SpoolMessage::VERSION, Perl $], $^X" );
