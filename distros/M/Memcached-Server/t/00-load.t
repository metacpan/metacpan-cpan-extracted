#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Memcached::Server' ) || print "Bail out!
";
}

diag( "Testing Memcached::Server $Memcached::Server::VERSION, Perl $], $^X" );
