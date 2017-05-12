#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mail::IMAPQueue' ) || print "Bail out!\n";
}

diag( "Testing Mail::IMAPQueue $Mail::IMAPQueue::VERSION, Perl $], $^X" );
