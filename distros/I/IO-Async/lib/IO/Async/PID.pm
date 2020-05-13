#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package IO::Async::PID;

use strict;
use warnings;
use base qw( IO::Async::Notifier );

our $VERSION = '0.77';

use Carp;

=head1 NAME

C<IO::Async::PID> - event callback on exit of a child process

=head1 SYNOPSIS

 use IO::Async::PID;
 use POSIX qw( WEXITSTATUS );

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 my $kid = $loop->fork(
    code => sub {
       print "Child sleeping..\n";
       sleep 10;
       print "Child exiting\n";
       return 20;
    },
 );

 print "Child process $kid started\n";

 my $pid = IO::Async::PID->new(
    pid => $kid,

    on_exit => sub {
       my ( $self, $exitcode ) = @_;
       printf "Child process %d exited with status %d\n",
          $self->pid, WEXITSTATUS($exitcode);
    },
 );

 $loop->add( $pid );

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Notifier> invokes its callback when a process
exits.

For most use cases, a L<IO::Async::Process> object provides more control of
setting up the process, connecting filehandles to it, sending data to and
receiving data from it.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_exit $exitcode

Invoked when the watched process exits.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 pid => INT

The process ID to watch. Must be given before the object has been added to the
containing L<IO::Async::Loop> object.

=head2 on_exit => CODE

CODE reference for the C<on_exit> event.

Once the C<on_exit> continuation has been invoked, the C<IO::Async::PID>
object is removed from the containing L<IO::Async::Loop> object.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{pid} ) {
      $self->loop and croak "Cannot configure 'pid' after adding to Loop";
      $self->{pid} = delete $params{pid};
   }

   if( exists $params{on_exit} ) {
      $self->{on_exit} = delete $params{on_exit};

      undef $self->{cb};

      if( my $loop = $self->loop ) {
         $self->_remove_from_loop( $loop );
         $self->_add_to_loop( $loop );
      }
   }

   $self->SUPER::configure( %params );
}

sub _add_to_loop
{
   my $self = shift;
   my ( $loop ) = @_;

   $self->pid or croak "Require a 'pid' in $self";

   $self->SUPER::_add_to_loop( @_ );

   # on_exit continuation gets passed PID value; need to replace that with
   # $self
   $self->{cb} ||= $self->_replace_weakself( sub {
      my $self = shift or return;
      my ( $exitcode ) = @_;

      $self->invoke_event( on_exit => $exitcode );

      # Since this is a oneshot, we'll have to remove it from the loop or
      # parent Notifier
      $self->remove_from_parent;
   } );

   $loop->watch_process( $self->pid, $self->{cb} );
}

sub _remove_from_loop
{
   my $self = shift;
   my ( $loop ) = @_;

   $loop->unwatch_process( $self->pid );
}

sub notifier_name
{
   my $self = shift;
   if( length( my $name = $self->SUPER::notifier_name ) ) {
      return $name;
   }

   return $self->{pid};
}

=head1 METHODS

=cut

=head2 pid

   $process_id = $pid->pid

Returns the underlying process ID

=cut

sub pid
{
   my $self = shift;
   return $self->{pid};
}

=head2 kill

   $pid->kill( $signal )

Sends a signal to the process

=cut

sub kill
{
   my $self = shift;
   my ( $signal ) = @_;

   kill $signal, $self->pid or croak "Cannot kill() - $!";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
