
use 5.005;
use Test::More tests => 6;
use Test::Exception;
use strict;
use warnings;

use Gopher::Server::ParseRequest;
use Gopher::Server::Response;
use Net::Gopher::Response::MenuItem;
use IO::Scalar;
my $request = Gopher::Server::ParseRequest->parse( '' );
my $data = "content\n";
my $content = $data;
my $fh = IO::Scalar->new(\$content);


dies_ok { Gopher::Server::Response->new() } "Empty constructor dies";
dies_ok { Gopher::Server::Response->new({ }) } "Unfilled args dies";

my $response = Gopher::Server::Response->new({
	request => $request, 
	fh      => $fh, 
});
ok( UNIVERSAL::isa( $response, 'Gopher::Server::Response' ), "ISA ok" );
ok( UNIVERSAL::isa( $response->request, 'Net::Gopher::Request' ), 
	"Request check" );

my $got;
my $out = IO::Scalar->new(\$got);
$response->print_to( $out );
close($out);
ok( $got eq $data, "Response returned" );
close($fh);

my @items;
push @items, Net::Gopher::Response::MenuItem->new({
	ItemType     => '0', 
	Display      => 'test1', 
	Selector     => '/test1', 
	Host         => 'localhost', 
	Port         => 70, 
});
push @items, Net::Gopher::Response::MenuItem->new({
	ItemType     => '1', 
	Display      => 'test2', 
	Selector     => '/test2', 
	Host         => 'localhost', 
	Port         => 70, 
});
$response = Gopher::Server::Response->new({
	request     => $request, 
	menu_items  => \@items, 
});
$data = "0test1\t/test1\tlocalhost\t70\r\n" . 
        "1test2\t/test2\tlocalhost\t70\r\n" . 
        ".\r\n";

$got = '';
$out = IO::Scalar->new(\$got);
$response->print_to( $out );
close($out);
ok( $got eq $data, "Menu Items returned" );

