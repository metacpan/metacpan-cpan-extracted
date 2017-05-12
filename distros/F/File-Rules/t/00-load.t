#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Rules' );
}

diag( "Testing File::Rules $File::Rules::VERSION, Perl $], $^X" );
