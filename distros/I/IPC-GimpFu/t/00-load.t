#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IPC::GimpFu' ) || print "Bail out!\n";
}

diag( "Testing IPC::GimpFu $IPC::GimpFu::VERSION, Perl $], $^X" );
