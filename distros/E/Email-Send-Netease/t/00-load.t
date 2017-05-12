#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Email::Send::Netease' ) || print "Bail out!\n";
}

diag( "Testing Email::Send::Netease $Email::Send::Netease::VERSION, Perl $], $^X" );
