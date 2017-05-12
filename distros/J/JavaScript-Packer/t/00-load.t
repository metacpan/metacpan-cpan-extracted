#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'JavaScript::Packer' );
}

diag( "Testing JavaScript::Packer $JavaScript::Packer::VERSION, Perl $], $^X" );
