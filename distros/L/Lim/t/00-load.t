#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'Lim' ) || print "Bail out!\n";
    use_ok( 'Lim::Agent' ) || print "Bail out!\n";
    use_ok( 'Lim::CLI' ) || print "Bail out!\n";
    use_ok( 'Lim::Plugins' ) || print "Bail out!\n";
    use_ok( 'Lim::RPC::Server' ) || print "Bail out!\n";
    use_ok( 'Lim::RPC::TLS' ) || print "Bail out!\n";
}

diag( "Testing Lim $Lim::VERSION, Perl $], $^X" );
