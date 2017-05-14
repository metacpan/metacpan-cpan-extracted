
use Test::More tests => 12;
use Test::Exception;
use strict;
use warnings;
use IO::Scalar;
use Net::Gopher::Request;
use Gopher::Server::RequestHandler::File;

my $request = Net::Gopher::Request->new( 'Gopher', 
	Host      => "localhost", 
	Port      => 70, 
	Selector  => '', 
);
my $class = 'Gopher::Server::RequestHandler::File';
my $root  = '/home/www/modules/t/Gopher/test_root';

dies_ok { $class->new({ }) } "No args, dies";

my $handler = $class->new({
	root => $root, 
	host => 'localhost', 
	port => 70, 
});
ok( $handler->isa($class), "isa check" );
ok( $handler->isa('Gopher::Server::RequestHandler'), "isa check" );

my $bad_path = '../../../../bin/noexist';
my $good_path = $handler->_canonpath('/noexist');
ok( $good_path eq "$root/noexist", "cannonpath" );
$good_path = $handler->_canonpath($bad_path);
ok( $good_path eq "$root/bin/noexist", "Can't go higher than root directory" );

my $selector = '/baz';
$request->selector( $selector );
my $path = $handler->_canonpath( $selector );

my $response = $handler->process( $request );
ok( $response, "processes request" );
ok( UNIVERSAL::isa($response, 'Gopher::Server::Response'), "isa check on returned request" );
ok( $response->request->selector() eq $selector, "Check selector" );

open(IN, '<', $path) or die "Can't open $good_path: $!\n";
my $data;
while(<IN>) { $data .= $_ }
close(IN);

my $got;
my $out = IO::Scalar->new(\$got);
$response->print_to( $out );
close($out);
ok( $got eq $data, "Menu Items returned" );


$request = Net::Gopher::Request->new( 'Gopher', 
	Host      => "localhost", 
	Port      => 70, 
	Selector  => '', 
);
$response = $handler->process( $request );
ok( $response, "processes request" );
ok( UNIVERSAL::isa($response, 'Gopher::Server::Response'), "isa check on returned request" );
ok( $response->request->selector() eq '', "Check selector" );

