
use Test::More tests => 8;
use strict;
use warnings;

use Gopher::Server::ParseRequest;

my $request = Gopher::Server::ParseRequest->parse( '' );
isa_ok( $request, 'Net::Gopher::Request' );
ok( $request->host eq 'localhost',  "Host is localhost" );
ok( $request->port == 70,           "Port 70" );
ok( $request->selector eq '',       "Empty selector" );

$request = Gopher::Server::ParseRequest->parse( "/foo" );
isa_ok( $request, 'Net::Gopher::Request' );
ok( $request->host eq 'localhost',  "Host is localhost" );
ok( $request->port == 70,           "Port 70" );
ok( $request->selector eq '/foo',   "Empty selector" );

