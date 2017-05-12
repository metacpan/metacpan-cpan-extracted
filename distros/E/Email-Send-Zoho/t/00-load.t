#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Email::Send::Zoho' ) || print "Bail out!\n";
}

diag( "Testing Email::Send::Zoho $Email::Send::Zoho::VERSION, Perl $], $^X" );
