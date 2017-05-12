#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 5;
use Test::HexString;
use Test::Refcount;

use IO::Async::Loop;
use IO::Async::Test;

use FCGI::Async::PSGI;

use TestFCGI;

my ( $S, $selfaddr ) = make_server_sock;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $responder;

my $fcgi = FCGI::Async::PSGI->new(
   loop => $loop,

   handle => $S,
   app => sub {
      my $env = shift;

      return sub {
         $responder = shift;
      }
   },
);

my $C = connect_client_sock( $selfaddr );

$C->syswrite(
   # Begin with FCGI_KEEP_CONN
   fcgi_trans( type => 1, id => 1, data => "\0\1\1\0\0\0\0\0" ) .
   # Parameters
   fcgi_trans( type => 4, id => 1, data =>
      fcgi_keyval( REQUEST_METHOD => "GET" ) . 
      fcgi_keyval( SCRIPT_NAME    => "" ) .
      fcgi_keyval( PATH_INFO      => "" ) . 
      fcgi_keyval( REQUEST_URI    => "/" ) .
      fcgi_keyval( QUERY_STRING   => "" ) .
      fcgi_keyval( SERVER_NAME    => "localhost" ) .
      fcgi_keyval( SERVER_PORT    => "80" ) .
      fcgi_keyval( SERVER_PROTOCOL => "HTTP/1.1" )
   ) .
   # End of parameters
   fcgi_trans( type => 4, id => 1, data => "" ) .
   # End of STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

wait_for { defined $responder };

is( ref $responder, "CODE", '$responder is a CODE ref' );

$responder->([
   200,
   [ "Content-Type" => "text/plain" ],
   [ "Deferred content here" ]
]);

my $CRLF = "\x0d\x0a";
my $expect_stdout = join( "", map "$_$CRLF",
      "Status: 200",
      "Content-Type: text/plain",
      '' ) .
   "Deferred content here";

my $expect;

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => $expect_stdout ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

my $buffer;

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI end request after deferred content' );

undef $responder;

$C->syswrite(
   # Begin with FCGI_KEEP_CONN
   fcgi_trans( type => 1, id => 1, data => "\0\1\1\0\0\0\0\0" ) .
   # Parameters
   fcgi_trans( type => 4, id => 1, data =>
      fcgi_keyval( REQUEST_METHOD => "GET" ) . 
      fcgi_keyval( SCRIPT_NAME    => "" ) .
      fcgi_keyval( PATH_INFO      => "" ) . 
      fcgi_keyval( REQUEST_URI    => "/" ) .
      fcgi_keyval( QUERY_STRING   => "" ) .
      fcgi_keyval( SERVER_NAME    => "localhost" ) .
      fcgi_keyval( SERVER_PORT    => "80" ) .
      fcgi_keyval( SERVER_PROTOCOL => "HTTP/1.1" )
   ) .
   # End of parameters
   fcgi_trans( type => 4, id => 1, data => "" ) .
   # End of STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

wait_for { defined $responder };

my $writer = $responder->([
   200,
   [ "Content-Type" => "text/plain" ],
]);

$expect_stdout = join( "", map "$_$CRLF",
      "Status: 200",
      "Content-Type: text/plain",
      '' );

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => $expect_stdout );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI STDOUT record after streamed responder' );

$writer->write( "Streamed " );

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => "Streamed " );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI STDOUT record after streamed writer write' );

$writer->write( "Output" );
$writer->close;

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => "Output" ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI STDOUT record after streamed writer write' );
