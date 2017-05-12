#!/usr/bin/perl -w

use strict;

use FCGI::Async;

use IO::Async::Stream;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new();

sub on_request
{
   my ( $fcgi, $req ) = @_;

   my %req_env = %{ $req->params };

   # Determine these however you like; perhaps examine $req
   my $handler = "./sample.cgi";
   my @handler_args = ();

   my $stdin = "";
   while( defined( my $line = $req->read_stdin_line ) ) {
      $stdin .= $line;
   }
   
   $fcgi->get_loop->open_child(
      command => [ $handler, @handler_args ],
      setup => [
         env => \%req_env,
      ],
      stdin => {
         from => $stdin,
      },
      stdout => {
         on_read => sub {
            my ( undef, $buffref ) = @_;

            $req->print_stdout( $$buffref );
            $$buffref = "";
 
            return 0;
         },
      },
      stderr => {
         on_read => sub {
            my ( undef, $buffref ) = @_;

            $req->print_stderr( $$buffref );
            $$buffref = "";

            return 0;
         },
      },
      on_finish => sub {
         my ( undef, $exitcode ) = @_;

         $req->finish( $exitcode );
      },
   );
}

my $fcgi = FCGI::Async->new(
   handle => \*STDIN,
   loop => $loop,
   on_request => \&on_request,
);

$loop->loop_forever();
