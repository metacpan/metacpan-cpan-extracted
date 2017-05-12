#!perl

use Test::More tests => 9;

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
    
    print "Content-Type: text/plain\n";
    print "Status: 200 Yay\n";
    print "Date: Thu, 19 Jan 2006 14:08:18 GMT\n";
    print "X-Field: 1\n";
    print "X-Field: 2\n";
    print "\n";
    print "Hello!";

    $response = $c->restore->response;
}

isa_ok( $response, 'HTTP::Response' );
is( $response->code, 200, 'Response Code' );
is( $response->message, 'Yay', 'Response Message' );
is( $response->protocol, 'HTTP/1.1', 'Response Protocol' );
is( $response->content, 'Hello!', 'Response Content' );
is( $response->content_length, 6, 'Response Content-Length' );
is( $response->content_type, 'text/plain', 'Response Content-Type' );
is( $response->header('Date'), 'Thu, 19 Jan 2006 14:08:18 GMT', 'Response Date' );
is_deeply( [ $response->header('X-Field') ], [ 1, 2 ], 'Response Header X-Field' );
