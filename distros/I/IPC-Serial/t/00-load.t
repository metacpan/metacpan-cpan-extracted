#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IPC::Serial' ) || print "Bail out!
";
}

diag( "Testing IPC::Serial $IPC::Serial::VERSION, Perl $], $^X" );
