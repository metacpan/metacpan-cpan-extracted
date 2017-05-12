#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Open' );
}

diag( "Testing File::Open $File::Open::VERSION, Perl $], $^X" );
