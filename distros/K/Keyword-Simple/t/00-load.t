#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Keyword::Simple' ) || print "Bail out!\n";
}

diag( "Testing Keyword::Simple $Keyword::Simple::VERSION, Perl $], $^X" );
