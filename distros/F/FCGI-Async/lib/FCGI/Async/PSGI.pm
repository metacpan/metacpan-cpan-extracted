#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package FCGI::Async::PSGI;

use strict;
use warnings;

use Carp;

use base qw( FCGI::Async );

our $VERSION = '0.22';

my $CRLF = "\x0d\x0a";

=head1 NAME

C<FCGI::Async::PSGI> - use C<PSGI> applications with C<FCGI::Async>

=head1 SYNOPSIS

 use FCGI::Async::PSGI;
 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new;

 my $fcgi = FCGI::Async::PSGI->new(
    port => 12345,
    app => sub {
       my $env = shift;

       return [
          200,
          [ "Content-Type" => "text/plain" ],
          [ "Hello, world!" ],
       ];
    },
 );

 $loop->add( $fcgi );

 $loop->loop_forever;

=head1 DESCRIPTION

This subclass of L<FCGI::Async> allows a FastCGI responder to use a L<PSGI>
application to respond to requests. It acts as a gateway between the FastCGI
connection from the webserver, and the C<PSGI> application. Aside from the use
of C<PSGI> instead of the C<on_request> callback, this class behaves similarly
to C<FCGI::Async>.

=cut

sub new
{
   # FCGI::Async's constructor tries to pass on all the args to $loop->listen
   # so we need to pull out app, if present
   my $class = shift;
   my %args = @_;

   my $app = delete $args{app};

   my $self = $class->SUPER::new(
      %args,
      on_request => sub {
         my $self = shift;
         my ( $req ) = @_;

         $self->process_request( $req );
      },
   );

   $self->configure( app => $app ) if defined $app;

   return $self;
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item app => CODE

Reference to the actual C<PSGI> application to use for responding to requests

=back

=cut

sub configure
{
   my $self = shift;
   my %args = @_;

   if( exists $args{app} ) {
      $self->{app} = delete $args{app};
   }

   $self->SUPER::configure( %args );
}

=head1 PSGI ENVIRONMENT

The following extra keys are supplied to the environment of the C<PSGI> app:

=over 8

=item C<fcgi.async>

The C<FCGI::Async::PSGI> object serving the request

=item C<fcgi.async.req>

The L<FCGI::Async::Request> object representing this particular request

=item C<io.async.loop>

The L<IO::Async::Loop> object that the C<FCGI::Async::PSGI> object is a member
of. This is also provided as C<fcgi.async.loop> for backward-compatibility
with version 0.21, but at some point will be removed.

=back

=cut

sub process_request
{
   my $self = shift;
   my ( $req ) = @_;

   # Much of this code stolen fro^W^Winspired by Plack::Handler::Net::FastCGI

   my %env = (
      %{ $req->params },
      'psgi.version'      => [1,0],
      'psgi.url_scheme'   => ($req->param("HTTPS")||"off") =~ m/^(?:on|1)/i ? "https" : "http",
      'psgi.input'        => $req->stdin,
      'psgi.errors'       => $req->stderr,
      'psgi.multithread'  => 0,
      'psgi.multiprocess' => 0,
      'psgi.run_once'     => 0,
      'psgi.nonblocking'  => 1,
      'psgi.streaming'    => 1,

      # Extensions
      'fcgi.async'      => $self,
      'fcgi.async.req'  => $req,
      'fcgi.async.loop' => $self->get_loop,
      'io.async.loop'   => $self->get_loop,
   );

   my $resp = $self->{app}->( \%env );

   my $responder = sub {
      my ( $status, $headers, $body ) = @{ +shift };

      $req->print_stdout( "Status: $status$CRLF" );
      while( my ( $header, $value ) = splice @$headers, 0, 2 ) {
         $req->print_stdout( "$header: $value$CRLF" );
      }
      $req->print_stdout( $CRLF );

      if( !defined $body ) {
         croak "Responder given no body in void context" unless defined wantarray;

         return $req->stdout_with_close;
      }

      if( ref $body eq "ARRAY" ) {
         $req->print_stdout( $_ ) for @$body;
         $req->finish( 0 );
      }
      else {
         $req->stream_stdout_then_finish(
            sub {
               local $/ = \8192;
               my $buffer = $body->getline;
               defined $buffer and return $buffer;

               $body->close;
               return undef;
            },
            0
         );
      }
   };

   if( ref $resp eq "ARRAY" ) {
      $responder->( $resp );
   }
   elsif( ref $resp eq "CODE" ) {
      $resp->( $responder );
   }
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<PSGI> - Perl Web Server Gateway Interface Specification

=item *

L<Plack::Handler::FCGI::Async> - FastCGI handler for Plack using L<FCGI::Async>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
