#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Defaults::Mauke' );
}

diag( "Testing Defaults::Mauke $Defaults::Mauke::VERSION, Perl $], $^X" );
