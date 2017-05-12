#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'FCGI::Daemon' ) || print "Bail out!
";
}

diag( "Testing FCGI::Daemon $FCGI::Daemon::VERSION, Perl $], $^X" );
