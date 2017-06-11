#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IPC::Queue::Duplex' ) || print "Bail out!
";
}

diag( "Testing IPC::Queue::Duplex $IPC::Queue::Duplex::VERSION, Perl $], $^X" );
