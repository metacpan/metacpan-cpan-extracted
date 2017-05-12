#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Linux::Pidfile' ) || print "Bail out!
";
}

diag( "Testing Linux::Pidfile $Linux::Pidfile::VERSION, Perl $], $^X" );
