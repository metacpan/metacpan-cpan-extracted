#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package IO::Async::Process::GracefulShutdown;

use strict;
use warnings;
use 5.010; # //
use base qw( IO::Async::Process );
IO::Async::Process->VERSION( '0.75' ); # ->finish_future

our $VERSION = '0.02';

=head1 NAME

C<IO::Async::Process::GracefulShutdown> - controlled shutdown of a process

=head1 SYNOPSIS

   use IO::Async::Process::GracefulShutdown;

   use IO::Async::Loop;
   my $loop = IO::Async::Loop;

   my $process = IO::Async::Process::GracefulShutdown->new(
      command => [ "my-proc" ],
   );

   $loop->add( $process );

   ...

   $process->shutdown( "TERM" )->get;

=head1 DESCRIPTION

This subclass of L<IO::Async::Process> adds a method to perform a shutdown of
the invoked process by sending a signal. If after some delay the process has
not yet exited, it is sent a C<SIGKILL> instead.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $params->{on_finish} //= sub {}; # back-compat did not require this

   $self->SUPER::_init( $params );
}

=head1 METHODS

=cut

=head2 shutdown

   $process->shutdown( $signal, %args )->get

Requests the process shut down by sending it the given signal (either
specified by name or number). If the process does not shut down after a
timeout, C<SIGKILL> is sent instead.

The returned future will complete when the process exits.

Takes the following named arguments:

=over 4

=item timeout => NUM

Optional. Number of seconds to wait for exit before sending C<SIGKILL>.
Defaults to 10 seconds.

=item on_kill => CODE

Optional. Callback to invoke if the timeout occurs and C<SIGKILL> is going to
be sent. Intended for printing or logging purposes; this doesn't have any
material effect on the process otherwise.

   $on_kill->( $process )

=back

=cut

sub shutdown
{
   my $self = shift;
   my ( $signal, %args ) = @_;

   my $timeout = $args{timeout} // 10;

   my $pid = $self->pid;

   $self->debug_printf( "KILL signal=%s", $signal );
   $self->kill( $signal );

   return Future->needs_any(
      $self->finish_future->then_done(),

      $self->loop->delay_future( after => $timeout )->then(
         sub {
            $args{on_kill}->( $self ) if $args{on_kill};

            $self->debug_printf( "KILL signal=KILL" );
            $self->kill( "KILL" );
            Future->done;
         })
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
