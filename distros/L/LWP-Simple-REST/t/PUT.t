#!/usr/bin/perl

use strict;
use warnings;

use LWP::Simple::REST qw/http_put/;
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

    sub setup {
        
    }
}

my $server = HTTPTest->new(3034)->background();

sleep 2;

my $string;

lives_ok {
    for ( 0 .. 2 ){
        $string = http_put( "http://localhost:3034", { argument1 => "one" } );
        last if $string;
        sleep 1;
    }
    fail("Cannot connect to server") if !$string;
} 'Request sent';

ok( $answer eq $string, "PUT: Answer should be a string" );

done_testing();

my $cnt = kill 9, $server;

