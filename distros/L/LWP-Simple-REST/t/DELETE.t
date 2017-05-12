#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use LWP::Simple::REST qw/http_delete/;
use Test::More;
use Test::Exception;

my $expected_answer = "argument1=one";

{
    package HTTPTest;
    use base qw/HTTP::Server::Simple::CGI/;

    sub handle_request{
        my $self = shift;
        my $cgi  = shift;

        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header, $expected_answer;
    }

    sub setup {

    }
}

my $server = HTTPTest->new(3031)->background();

sleep 2;

my $string;

lives_ok {
    for ( 0 .. 2 ){
        $string = http_delete( "http://localhost:3031", { argument1 => "one" } );
        last if $string;
        sleep 1;
    }
    fail("Cannot connect on server") if !$string;
} 'Request sent';

ok( $expected_answer eq $string, "Answer should be a string" );

done_testing();

my $cnt = kill 9, $server;

