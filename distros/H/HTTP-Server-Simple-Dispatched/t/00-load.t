#!perl -T

use Test::More tests => 2;

BEGIN {
	
	use_ok(q(HTTP::Server::Simple::Dispatched));
	use_ok(q(HTTP::Server::Simple::Dispatched::Request));
}

diag( "Testing HTTP::Server::Simple::Dispatched $HTTP::Server::Simple::Dispatched::VERSION, Perl $], $^X" );
