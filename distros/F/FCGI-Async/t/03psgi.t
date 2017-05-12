#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More tests => 15;
use Test::Identity;
use Test::HexString;
use Test::Refcount;

use IO::Async::Loop;
use IO::Async::Test;

use FCGI::Async::PSGI;

use TestFCGI;

my ( $S, $selfaddr ) = make_server_sock;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $received_env;

my $fcgi = FCGI::Async::PSGI->new(
   loop => $loop,

   handle => $S,
   app => sub {
      # Simplest PSGI app
      $received_env = shift;
      return [
         200,
         [ "Content-Type" => "text/plain" ],
         [ "Hello, world" ],
      ];
   },
);

ok( defined $fcgi, 'defined $fcgi' );
isa_ok( $fcgi, "FCGI::Async::PSGI", '$fcgi isa FCGI::Async::PSGI' );
isa_ok( $fcgi, "FCGI::Async", '$fcgi isa FCGI::Async' );

# One ref in the Loop as well as this lexical variable
is_refcount( $fcgi, 2, '$fcgi has refcount 2 initially' );

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

wait_for { defined $received_env };

# Some keys are awkward, handle them first
ok( defined(delete $received_env->{'psgi.input'}), "psgi.input exists" );
ok( defined(delete $received_env->{'psgi.errors'}), "psgi.errors exists" );

identical( delete $received_env->{'fcgi.async'}, $fcgi, "fcgi.async is \$fcgi" );
can_ok( delete $received_env->{'fcgi.async.req'}, "params" );
identical( delete $received_env->{'fcgi.async.loop'}, $loop, "fcgi.async.loop is \$loop" );
identical( delete $received_env->{'io.async.loop'}, $loop, "io.async.loop is \$loop" );

is_deeply( $received_env,
   {
      PATH_INFO       => "",
      QUERY_STRING    => "",
      REQUEST_METHOD  => "GET",
      REQUEST_URI     => "/",
      SCRIPT_NAME     => "",
      SERVER_NAME     => "localhost",
      SERVER_PORT     => "80",
      SERVER_PROTOCOL => "HTTP/1.1",

      'psgi.version'      => [1,0],
      'psgi.url_scheme'   => "http",
      'psgi.run_once'     => 0,
      'psgi.multiprocess' => 0,
      'psgi.multithread'  => 0,
      'psgi.streaming'    => 1,
      'psgi.nonblocking'  => 1,
   },
   'received $env in PSGI app' );

my $CRLF = "\x0d\x0a";
my $expect_stdout = join( "", map "$_$CRLF",
      "Status: 200",
      "Content-Type: text/plain",
      '' ) .
   "Hello, world";

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

is_hexstr( $buffer, $expect, 'FastCGI end request record' );

$fcgi->configure(
   app => sub {
      my $env = shift;
      my $input = delete $env->{'psgi.input'};

      my $content = "";
      while( $input->read( my $buffer, 1024 ) ) {
         $content .= $buffer;
      }

      return [
         200,
         [ "Content-Type" => "text/plain" ],
         [ "Input was: $content" ],
      ];
   }
);

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
   # STDIN
   fcgi_trans( type => 5, id => 1, data => "Some data on STDIN" ) .
   # End of STDIN
   fcgi_trans( type => 5, id => 1, data => "" )
);

$expect_stdout = join( "", map "$_$CRLF",
      "Status: 200",
      "Content-Type: text/plain",
      '' ) .
   "Input was: Some data on STDIN";

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => $expect_stdout ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI request/response with STDIN reading' );

$fcgi->configure(
   app => sub {
      my $env = shift;

      $env->{'psgi.errors'}->print( "An error line here\n" );

      return [
         200,
         [ "Content-Type" => "text/plain" ],
         [ "" ],
      ];
   }
);

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

$expect_stdout = join( "", map "$_$CRLF",
      "Status: 200",
      "Content-Type: text/plain",
      '' ) .
   "";

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => $expect_stdout ) .
   # STDERR
   fcgi_trans( type => 7, id => 1, data => "An error line here\n" ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End of STDERR
   fcgi_trans( type => 7, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI request/response with STDERR printing' );

$fcgi->configure(
   app => sub {
      my $env = shift;

      open my $body, "<", \"Here is a IO-like string";

      return [
         200,
         [ "Content-Type" => "text/plain" ],
         $body,
      ];
   }
);

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

# This STDOUT will come in two pieces
$expect_stdout = join( "", map "$_$CRLF",
      "Status: 200",
      "Content-Type: text/plain",
      '' );

$expect =
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => $expect_stdout ) .
   # STDOUT
   fcgi_trans( type => 6, id => 1, data => "Here is a IO-like string" ) .
   # End of STDOUT
   fcgi_trans( type => 6, id => 1, data => "" ) .
   # End request
   fcgi_trans( type => 3, id => 1, data => "\0\0\0\0\0\0\0\0" );

$buffer = "";

wait_for_stream { length $buffer >= length $expect } $C => $buffer;

is_hexstr( $buffer, $expect, 'FastCGI request/response with IO-like body' );
