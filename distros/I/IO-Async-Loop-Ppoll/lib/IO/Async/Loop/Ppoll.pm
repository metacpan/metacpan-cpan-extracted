#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2011 -- leonerd@leonerd.org.uk

package IO::Async::Loop::Ppoll;

use strict;
use warnings;

our $VERSION = '0.09';
use constant API_VERSION => '0.49';

use IO::Async::Loop::Poll 0.18;
use base qw( IO::Async::Loop::Poll );

use Carp;

use IO::Ppoll qw( POLLIN POLLOUT POLLHUP );

use POSIX qw( EINTR SIG_BLOCK SIG_UNBLOCK sigprocmask sigaction );

use constant _CAN_WATCHDOG => 1;
use constant WATCHDOG_ENABLE => IO::Async::Loop->WATCHDOG_ENABLE;

=head1 NAME

C<IO::Async::Loop::Ppoll> - use C<IO::Async> with C<ppoll(2)>

=head1 SYNOPSIS

 use IO::Async::Loop::Ppoll;

 my $loop = IO::Async::Loop::Ppoll->new();

 $loop->add( ... );

 $loop->add( IO::Async::Signal->new(
       name =< 'HUP',
       on_receipt => sub { ... },
 ) );

 $loop->loop_forever();

=head1 DESCRIPTION

This subclass of C<IO::Async::Loop::Poll> uses an C<IO::Ppoll> object instead
of a C<IO::Poll> to perform read-ready and write-ready tests so that they can
be mixed with signal handling.

The C<ppoll()> system call atomically switches the process's signal mask,
performs a wait exactly as C<poll()> would, then switches it back. This allows
a process to block the signals it cares about, but switch in an empty signal
mask during the poll, allowing it to handle file IO and signals concurrently.

=head1 CONSTRUCTOR

=cut

=head2 $loop = IO::Async::Loop::Ppoll->new( %args )

This function returns a new instance of a C<IO::Async::Loop::Ppoll> object.
It takes the following named arguments:

=over 8

=item C<poll>

The C<IO::Ppoll> object to use for notification. Optional; if a value is not
given, a new C<IO::Ppoll> object will be constructed.

=back

=cut

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   my $poll = delete $args{poll};

   $poll ||= IO::Ppoll->new();

   my $self = $class->SUPER::new( %args, poll => $poll );

   $self->{signals} = {};

   return $self;
}

=head1 METHODS

As this is a subclass of L<IO::Async::Loop::Poll>, all of its methods are
inherited. Expect where noted below, all of the class's methods behave
identically to C<IO::Async::Loop::Poll>.

=cut

sub DESTROY
{
   my $self = shift;

   foreach my $signal ( keys %{ $self->{signals} } ) {
      $self->unwatch_signal( $signal );
   }
}

=head2 $count = $loop->loop_once( $timeout )

This method calls the C<poll()> method on the stored C<IO::Ppoll> object,
passing in the value of C<$timeout>, and processes the results of that call.
It returns the total number of C<IO::Async::Notifier> callbacks invoked, or
C<undef> if the underlying C<poll()> method returned an error. If the
C<poll()> was interrupted by a signal, then 0 is returned instead.

=cut

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   $self->_adjust_timeout( \$timeout );

   my $poll = $self->{poll};

   my $pollret = $poll->poll( $timeout );

   return undef if ( !defined $pollret or $pollret == -1 ) and $! != EINTR;

   my $count = 0;

   alarm( IO::Async::Loop->WATCHDOG_INTERVAL ) if WATCHDOG_ENABLE;

   my $signals = $self->{signals};
   foreach my $sigslot ( values %$signals ) {
      if( $sigslot->[1] ) {
         $sigslot->[0]->();
         $sigslot->[1] = 0;
         $count++;
      }
   }

   return $count + $self->post_poll();
}

# override
sub watch_signal
{
   my $self = shift;
   my ( $signal, $code ) = @_;

   exists $SIG{$signal} or croak "Unrecognised signal name $signal";

   # We cannot simply set $SIG{$signal} = $code here, because of perl bug
   #   http://rt.perl.org/rt3/Ticket/Display.html?id=82040
   # Instead, we'll store a tiny piece of code that just sets a flag, and
   # check the flags on return from the epoll_pwait call.

   $self->{signals}{$signal} = [ $code, 0, $SIG{$signal} ];
   my $pending = \$self->{signals}{$signal}[1];

   my $signum = $self->signame2num( $signal );
   sigprocmask( SIG_BLOCK, POSIX::SigSet->new( $signum ) );

   # Note this is an unsafe signal handler, and as such it should do as little
   # as possible.
   my $sigaction = POSIX::SigAction->new( sub { $$pending = 1 } );
   sigaction( $signum, $sigaction ) or croak "Unable to sigaction - $!";
}

# override
sub unwatch_signal
{
   my $self = shift;
   my ( $signal ) = @_;

   exists $SIG{$signal} or croak "Unrecognised signal name $signal";

   # When we saved the original value, we might have got an undef. But %SIG
   # doesn't like having undef assigned back in, so we need to translate
   $SIG{$signal} = $self->{signals}{$signal}[2] || 'DEFAULT';

   delete $self->{signals}{$signal};
   
   my $signum = $self->signame2num( $signal );

   sigprocmask( SIG_UNBLOCK, POSIX::SigSet->new( $signum ) );
}

=head1 SEE ALSO

=over 4

=item *

L<IO::Ppoll> - Object interface to Linux's C<ppoll()> call

=item *

L<IO::Async::Loop::Poll> - a set using an C<IO::Poll> object

=back 

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
