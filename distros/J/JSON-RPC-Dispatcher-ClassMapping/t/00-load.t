#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'JSON::RPC::Dispatcher::ClassMapping' ) || print "Bail out!\n";
}

diag( "Testing JSON::RPC::Dispatcher::ClassMapping $JSON::RPC::Dispatcher::ClassMapping::VERSION, Perl $], $^X" );
