#!/usr/bin/perl -w

use strict;

use FCGI::Async;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new();

sub on_request
{
   my ( $fcgi, $req ) = @_;

   my $env = $req->params();

   my $page = "";

   my $path = $env->{PATH_INFO} || "/";
   my $qs   = $env->{QUERY_STRING} || "";

   my %queryparams = map { m/^(.*?)=(.*)$/ && ( $1, $2 ) } split( m/&/, $qs );

   $page = "<h1>Request Variables</h1>\n";
   
   $page .= "<h2>Basics</h2>\n" .
           "<p>Path: <tt>$path</tt></p>\n";

   if ( keys %queryparams ) {
      $page .= "<h2>Query parameters</h2>\n" .
              "<table border=\"1\">\n";

      foreach my $key ( sort keys %queryparams ) {
         $page .= "<tr><td>$key</td><td><tt>$queryparams{$key}</tt></td></tr>\n";
      }

      $page .= "</table>\n";
   }

   $page .= "<h2>Environment variables</h2>\n";

   $page .= "<table>\n";

   foreach my $key ( sort keys %$env ) {
      $page .= "<tr><td>$key</td><td><tt>$env->{$key}</tt></td></tr>\n";
   }

   $page .= "</table>\n";

   $req->print_stdout(
      "Content-type: text/html\r\n" .
      "Content-length: " . length( $page ) . "\r\n" .
      "\r\n" .
      $page . "\r\n"
   );

   $req->finish();
}

my $fcgi = FCGI::Async->new(
   handle => \*STDIN,
   loop => $loop,
   on_request => \&on_request,
);

$loop->loop_forever();
