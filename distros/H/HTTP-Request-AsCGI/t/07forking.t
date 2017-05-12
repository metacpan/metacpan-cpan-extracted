#!perl

use strict;
use warnings;

use Config;
use IO::File;
use HTTP::Request;
use HTTP::Request::AsCGI;
use Test::More;

unless ( $Config{d_fork} ) {
    plan skip_all => 'This test requires a plattform that supports fork()';
}

plan tests => 8;

my $response;

{
    my $r = HTTP::Request->new( GET => 'http://www.host.com/' );
    my $c = HTTP::Request::AsCGI->new($r);

    my $kid = fork();

    unless ( defined $kid ) {
        die("Can't fork() kid: $!");
    }

    unless ( $kid ) {

        $c->setup;

        print "HTTP/1.0 200 OK\n";
        print "Content-Type: text/plain\n";
        print "Status: 200\n";
        print "X-Field: 1\n";
        print "X-Field: 2\n";
        print "\n";
        print "Hello!";

        $c->restore;

        exit(0);
    }

    waitpid( $kid, 0 );

    $response = $c->response;
}

isa_ok( $response, 'HTTP::Response' );
is( $response->code, 200, 'Response Code' );
is( $response->message, 'OK', 'Response Message' );
is( $response->protocol, 'HTTP/1.0', 'Response Protocol' );
is( $response->content, 'Hello!', 'Response Content' );
is( $response->content_length, 6, 'Response Content-Length' );
is( $response->content_type, 'text/plain', 'Response Content-Type' );
is_deeply( [ $response->header('X-Field') ], [ 1, 2 ], 'Response Header X-Field' );
