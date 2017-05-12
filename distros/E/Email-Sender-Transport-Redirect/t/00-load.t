#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Email::Sender::Transport::Redirect' ) || print "Bail out!\n";
}

diag( "Testing Email::Sender::Transport::Redirect $Email::Sender::Transport::Redirect::VERSION, Perl $], $^X" );
