#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package IO::Async::Protocol::LineStream;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( IO::Async::Protocol::Stream );

use Carp;

=head1 NAME

C<IO::Async::Protocol::LineStream> - stream-based protocols using lines of
text

=head1 SYNOPSIS

Most likely this class will be subclassed to implement a particular network
protocol.

 package Net::Async::HelloWorld;

 use strict;
 use warnings;
 use base qw( IO::Async::Protocol::LineStream );

 sub on_read_line
 {
    my $self = shift;
    my ( $line ) = @_;

    if( $line =~ m/^HELLO (.*)/ ) {
       my $name = $1;

       $self->invoke_event( on_hello => $name );
    }
 }

 sub send_hello
 {
    my $self = shift;
    my ( $name ) = @_;

    $self->write_line( "HELLO $name" );
 }

This small example elides such details as error handling, which a real
protocol implementation would be likely to contain.

=head1 DESCRIPTION

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_read_line $line

Invoked when a new complete line of input is received.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 on_read_line => CODE

CODE reference for the C<on_read_line> event.

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init;

   $self->{eol} = "\x0d\x0a";
   $self->{eol_pattern} = qr/\x0d?\x0a/;
}

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_read_line )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );
}

sub on_read
{
   my $self = shift;
   my ( $buffref, $eof ) = @_;

   # Easiest to run each event individually, in case it returns a CODE ref
   $$buffref =~ s/^(.*?)$self->{eol_pattern}// or return 0;

   return $self->invoke_event( on_read_line => $1 ) || 1;
}

=head1 METHODS

=cut

=head2 write_line

   $lineprotocol->write_line( $text )

Writes a line of text to the transport stream. The text will have the
end-of-line marker appended to it; C<$text> should not end with it.

=cut

sub write_line
{
   my $self = shift;
   my ( $line, @args ) = @_;

   $self->write( "$line$self->{eol}", @args );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
