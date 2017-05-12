#!/usr/bin/perl

use strict;
use warnings;

use LWP::Simple::REST qw/http_post/;
use Test::More;
use Test::Exception;

my $answer = "argument1=one";

{
    package HTTPTest;
    use base qw/HTTP::Server::Simple::CGI/;

    sub handle_request{
        my $self = shift;
        my $cgi  = shift;

        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header, $answer;
    }
}

my $server = HTTPTest->new(3036)->background();

sleep 2;

my $string;
lives_ok {
    for ( 0 .. 2 ){
        $string = http_post( "http://localhost:3036", { argument1 => "one" } );
	last if $string;
        sleep 1;
    }
    fail("Cannot connect to server") if !$string;
} 'Request sent';

ok( $answer eq $string, "Answer should be a string" );

done_testing();

my $cnt = kill 9, $server;

