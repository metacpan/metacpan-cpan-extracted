#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Google::Code::Upload' );
}

diag( "Testing Google::Code::Upload $Google::Code::Upload::VERSION, Perl $], $^X" );
