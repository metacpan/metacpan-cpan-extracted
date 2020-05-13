#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2011 -- leonerd@leonerd.org.uk

package IO::Async::Signal;

use strict;
use warnings;
use base qw( IO::Async::Notifier );

our $VERSION = '0.77';

use Carp;

=head1 NAME

C<IO::Async::Signal> - event callback on receipt of a POSIX signal

=head1 SYNOPSIS

 use IO::Async::Signal;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $signal = IO::Async::Signal->new(
    name => "HUP",

    on_receipt => sub {
        print "I caught SIGHUP\n";
    },
 );

 $loop->add( $signal );

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Notifier> invokes its callback when a particular
POSIX signal is received.

Multiple objects can be added to a C<Loop> that all watch for the same signal.
The callback functions will all be invoked, in no particular order.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_receipt

Invoked when the signal is received.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 name => STRING

The name of the signal to watch. This should be a bare name like C<TERM>. Can
only be given at construction time.

=head2 on_receipt => CODE

CODE reference for the C<on_receipt> event.

Once constructed, the C<Signal> will need to be added to the C<Loop> before it
will work.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   my $name = delete $params->{name} or croak "Expected 'name'";

   $name =~ s/^SIG//; # Trim a leading "SIG"

   $self->{name} = $name;

   $self->SUPER::_init( $params );
}

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{on_receipt} ) {
      $self->{on_receipt} = delete $params{on_receipt};

      undef $self->{cb}; # Will be lazily constructed when needed

      if( my $loop = $self->loop ) {
         $self->_remove_from_loop( $loop );
         $self->_add_to_loop( $loop );
      }
   }

   unless( $self->can_event( 'on_receipt' ) ) {
      croak 'Expected either a on_receipt callback or an ->on_receipt method';
   }

   $self->SUPER::configure( %params );
}

sub _add_to_loop
{
   my $self = shift;
   my ( $loop ) = @_;

   $self->{cb} ||= $self->make_event_cb( 'on_receipt' );

   $self->{id} = $loop->attach_signal( $self->{name}, $self->{cb} );
}

sub _remove_from_loop
{
   my $self = shift;
   my ( $loop ) = @_;

   $loop->detach_signal( $self->{name}, $self->{id} );
   undef $self->{id};
}

sub notifier_name
{
   my $self = shift;
   if( length( my $name = $self->SUPER::notifier_name ) ) {
      return $name;
   }

   return $self->{name};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
