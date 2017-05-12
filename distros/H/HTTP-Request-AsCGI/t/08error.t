#!perl

use Test::More tests => 12;

use strict;
use warnings;

use IO::File;
use HTTP::Request;
use HTTP::Request::AsCGI;

my $response;

{
    my $r = HTTP::Request->new( GET => 'http://www.host.com/' );
    my $c = HTTP::Request::AsCGI->new($r);

    $c->setup;

    $response = $c->restore->response;
}

isa_ok( $response, 'HTTP::Response' );
is( $response->code, 500, 'Response Code' );
is( $response->message, 'Internal Server Error', 'Response Message' );
is( $response->protocol, 'HTTP/1.1', 'Response Protocol' );
is( $response->content_type, 'text/html', 'Response Content-Type' );
ok( length($response->content) > 0, 'Response Content' );

{
    my $r = HTTP::Request->new( GET => 'http://www.host.com/' );
    my $c = HTTP::Request::AsCGI->new($r);

    $c->setup;
    
    print "Content-Type: text/plain\n";
    print "Status: 500 Borked\n";
    print "\n";
    print "Borked!";

    $response = $c->restore->response;
}

isa_ok( $response, 'HTTP::Response' );
is( $response->code, 500, 'Response Code' );
is( $response->message, 'Borked', 'Response Message' );
is( $response->protocol, 'HTTP/1.1', 'Response Protocol' );
is( $response->content_type, 'text/plain', 'Response Content-Type' );
is( $response->content, 'Borked!', 'Response Content' );
