#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use LWP::Simple::REST qw/json_post/;
use Test::More;
use Test::Exception;
use Try::Tiny;

my $answer = '{"daftpunk":"around the world"}';

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

my $server = HTTPTest->new(3032)->background();

sleep 2;

my $object;
my $error = 0;

lives_ok {
    for ( 0 .. 2 ){
        try{
            $object = json_post( "http://localhost:3032", { anyparameter => "not json yet" } );
            sleep 1;
        }
        catch{
            $error++;
        };
        last if $object;
    }
    #BAIL_OUT("Cannot connect to server") if $error == 3;
    die "Cannot connect to server" if $error == 3;
} 'Request sent';

my $expected_object = {
    daftpunk => "around the world",
};

is_deeply( $expected_object, $object, "Answer should be a string" );

done_testing();

my $cnt = kill 9, $server;

