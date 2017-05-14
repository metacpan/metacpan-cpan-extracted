
use Test::More tests => 2;
use Test::Exception;
use strict;
use warnings;
use Net::Gopher::Request;
use Gopher::Server::RequestHandler;

my $request = Net::Gopher::Request->new( 'Gopher', 
	Host      => "localhost", 
	Port      => 70, 
	Selector  => '', 
);
my $class = 'Gopher::Server::RequestHandler';
dies_ok { $class->new({ }) }           'Abstract class';
dies_ok { $class->process($request) }  'Abstract class';

