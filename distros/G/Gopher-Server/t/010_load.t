
use Test::More tests => 8;
use strict;
use warnings;

BEGIN {
	use_ok( 'Gopher::Server::ParseRequest' );
	use_ok( 'Gopher::Server::RequestHandler' );
	use_ok( 'Gopher::Server::RequestHandler::File' );
	use_ok( 'Gopher::Server::RequestHandler::DBI' );
	use_ok( 'Gopher::Server::Response' );
	use_ok( 'Gopher::Server::TypeMapper' );
}

ok( 
	Gopher::Server::RequestHandler::File->isa( 
		'Gopher::Server::RequestHandler'
	), 
	"::RequestHandler::File base class check"
);
ok(
	Gopher::Server::RequestHandler::DBI->isa( 
		'Gopher::Server::RequestHandler' 
	), 
	"::RequestHandler::DBI base class check" 
);

