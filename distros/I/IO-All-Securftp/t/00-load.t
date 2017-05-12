#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IO::All::Securftp' ) || BAIL_OUT "Couldn't load IO::All::Securftp";
}

diag( "Testing IO::All::Securftp $IO::All::Securftp::VERSION, Perl $], $^X" );
