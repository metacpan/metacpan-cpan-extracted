#!/usr/bin/perl -w

use strict;

use FCGI::Async;

use IO::Async::Stream;
use IO::Async::Loop;

my $FORTUNE = "/usr/games/fortune";

my $loop = IO::Async::Loop->new();

sub on_request
{
   my ( $fcgi, $req ) = @_;
   
   my $kid = $fcgi->get_loop->open_child(
      command => [ $FORTUNE ],
      stdout => {
         on_read => sub {
            my ( undef, $buffref, $closed ) = @_;

            if( $$buffref =~ s{^(.*?)\n}{} ) {
               $req->print_stdout( "<p>$1</p>" );
               return 1;
            }

            if( $closed ) {
               # Deal with a final partial line the child may have written
               $req->print_stdout( "<p>$$buffref</p>" ) if length $$buffref;
               $req->print_stdout( "</body></html>" );
            }

            return 0;
         },
      },
      stderr => {
         on_read => sub {
            my ( undef, $buffref, $closed ) = @_;

            if( $$buffref =~ s{^(.*?)\n}{} ) {
               $req->print_stderr( $1 );
               return 1;
            }

            if( $closed ) {
               # Deal with a final partial line the child may have written
               $req->print_stderr( "$$buffref\n" ) if length $$buffref;
            }

            return 0;
         },
      },

      on_finish => sub {
         my ( undef, $exitcode ) = @_;
         $req->finish( $exitcode );
      },
   );

   if( !defined $kid ) {
      $req->print_stdout(
         "Content-type: text/plain\r\n" .
         "\r\n" .
         "Could not run $FORTUNE - $!\r\n"
      );

      $req->finish;
      return;
   }

   # Print CGI header
   $req->print_stdout(
      "Content-type: text/html\r\n" .
      "\r\n" .
      "<html>" . 
      " <head><title>Fortune</title></head>" . 
      " <body><h1>$FORTUNE says:</h1>"
   );
}

my $fcgi = FCGI::Async->new(
   handle => \*STDIN,
   loop => $loop,
   on_request => \&on_request,
);

$loop->loop_forever();
