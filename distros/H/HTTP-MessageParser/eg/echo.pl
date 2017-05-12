#!/usr/bin/perl

use strict;
use warnings;
use bytes;

use HTTP::MessageParser qw[];
use HTTP::Request       qw[];
use HTTP::Response      qw[];
use IO::Socket::INET    qw[];
use Sys::Hostname       qw[];

my $server = IO::Socket::INET->new(
    Listen => 5,
    Proto  => 'tcp'
) or die qq/Failed to create server socket. Reason: '$!'./;

printf "http://%s:%d/\n", Sys::Hostname::hostname(), $server->sockport;

$SIG{PIPE} = 'IGNORE';

while ( my $connection = $server->accept ) {

    my ( $request, $response );

    eval {

        my $message;

        while ( my $line = $connection->getline ) {
            next if !$message && $line eq "\x0D\x0A";
            $message .= $line;
            last if $message =~ /\x0D\x0A\x0D\x0A$/;
        }

        my ( $method, $uri, $protocol, $header )
          = HTTP::MessageParser->parse_request($message);

        $request = HTTP::Request->new( $method, $uri, $header );
        $request->protocol($protocol);
    };

    if ( $@ ) {
        $response = HTTP::Response->new( 400, 'Bad Request' );
        $response->content( $response->error_as_HTML );
        $response->content_type('text/html');
        $response->content_length( length $response->content );
    }
    else {

        if (    $request->header('Transfer-Encoding')
             && $request->header('Transfer-Encoding') =~ /chunked/i ) {

            $response = HTTP::Response->new( 411, 'Length Required' );

            goto RESPONSE;
        }

        if (    $request->header('Expect')
             && $request->header('Expect') =~ /100-continue/i ) {

            $connection->write("HTTP/1.1 100 Continue\x0D\x0A\x0D\x0A")
              or goto DONE;
        }

        $response = HTTP::Response->new( 200, 'OK' );
        $response->content( $request->as_string("\x0D\x0A") );
        $response->content_type('text/plain');
        $response->content_length( length $response->content );

        if ( $request->content_length ) {

            my $length  = $request->content_length;
            my $content = $response->content_ref;
            my $offset  = length $$content;

            $connection->read( $$content, $length, $offset )
              or goto DONE;

            $response->content_length( $length + $offset );
        }
    }

  RESPONSE:

    $response->protocol('HTTP/1.1');
    $response->header( 'Connection' => 'Close' );

    $connection->write( $response->as_string("\x0D\x0A") );

  DONE:

    $connection->close;
}
