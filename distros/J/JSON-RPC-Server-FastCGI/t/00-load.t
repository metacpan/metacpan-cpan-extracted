#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'JSON::RPC::Server::FastCGI' );
}

diag( "Testing JSON::RPC::Server::FastCGI $JSON::RPC::Server::FastCGI::VERSION, Perl $], $^X" );
