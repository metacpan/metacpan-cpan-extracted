#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2020 -- leonerd@leonerd.org.uk

package IO::Async::Loop::Poll;

use strict;
use warnings;

our $VERSION = '0.77';
use constant API_VERSION => '0.49';

use base qw( IO::Async::Loop );

use Carp;

use IO::Poll qw( POLLIN POLLOUT POLLPRI POLLHUP POLLERR );

use Errno qw( EINTR );
use Fcntl qw( S_ISREG );

# Only Linux, or FreeBSD 8.0 and above, are known always to be able to report
# EOF conditions on filehandles using POLLHUP
use constant _CAN_ON_HANGUP =>
   ( $^O eq "linux" ) ||
   ( $^O eq "freebsd" and do { no warnings 'numeric'; (POSIX::uname)[2] >= 8.0 } );

# poll() on most platforms claims that ISREG files are always read- and
# write-ready, but not on MSWin32. We need to fake this
use constant FAKE_ISREG_READY => IO::Async::OS->HAVE_FAKE_ISREG_READY;
# poll() on most platforms indicates POLLOUT when connect() fails, but not on
# MSWin32. Have to poll also for POLLPRI in that case
use constant POLL_CONNECT_POLLPRI => IO::Async::OS->HAVE_POLL_CONNECT_POLLPRI;

use constant _CAN_WATCHDOG => 1;
use constant WATCHDOG_ENABLE => IO::Async::Loop->WATCHDOG_ENABLE;

=head1 NAME

C<IO::Async::Loop::Poll> - use C<IO::Async> with C<poll(2)>

=head1 SYNOPSIS

Normally an instance of this class would not be directly constructed by a
program. It may however, be useful for runinng L<IO::Async> with an existing
program already using an C<IO::Poll> object.

 use IO::Poll;
 use IO::Async::Loop::Poll;

 my $poll = IO::Poll->new;
 my $loop = IO::Async::Loop::Poll->new( poll => $poll );

 $loop->add( ... );

 while(1) {
    my $timeout = ...
    my $ret = $poll->poll( $timeout );
    $loop->post_poll;
 }

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses the C<poll(2)> system call to perform
read-ready and write-ready tests.

By default, this loop will use the underlying C<poll()> system call directly,
bypassing the usual L<IO::Poll> object wrapper around it because of a number
of bugs and design flaws in that class; namely

=over 2

=item *

L<https://rt.cpan.org/Ticket/Display.html?id=93107> - IO::Poll relies on
stable stringification of IO handles

=item *

L<https://rt.cpan.org/Ticket/Display.html?id=25049> - IO::Poll->poll() with no
handles always returns immediately

=back

However, to integrate with existing code that uses an C<IO::Poll> object, a
C<post_poll> can be called immediately after the C<poll> method that
C<IO::Poll> object. The appropriate mask bits are maintained on the
C<IO::Poll> object when notifiers are added or removed from the loop, or when
they change their C<want_*> status. The C<post_poll> method inspects the
result bits and invokes the C<on_read_ready> or C<on_write_ready> methods on
the notifiers.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $loop = IO::Async::Loop::Poll->new( %args )

This function returns a new instance of a C<IO::Async::Loop::Poll> object. It
takes the following named arguments:

=over 8

=item C<poll>

The C<IO::Poll> object to use for notification. Optional; if a value is not
given, the underlying C<IO::Poll::_poll()> function is invoked directly,
outside of the object wrapping.

=back

=cut

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   my $poll = delete $args{poll};

   my $self = $class->__new( %args );

   $self->{poll} = $poll;
   $self->{pollmask} = {};

   return $self;
}

=head1 METHODS

=cut

=head2 post_poll

   $count = $loop->post_poll

This method checks the returned event list from a C<IO::Poll::poll> call,
and calls any of the notification methods or callbacks that are appropriate.
It returns the total number of callbacks that were invoked; that is, the
total number of C<on_read_ready> and C<on_write_ready> callbacks for 
C<watch_io>, and C<watch_time> event callbacks.

=cut

sub post_poll
{
   my $self = shift;

   my $iowatches = $self->{iowatches};
   my $poll      = $self->{poll};

   my $count = 0;

   alarm( IO::Async::Loop->WATCHDOG_INTERVAL ) if WATCHDOG_ENABLE;

   foreach my $fd ( keys %$iowatches ) {
      my $watch = $iowatches->{$fd} or next;

      my $events = $poll ? $poll->events( $watch->[0] )
                         : $self->{pollevents}{$fd};
      if( FAKE_ISREG_READY and $self->{fake_isreg}{$fd} ) {
         $events |= $self->{fake_isreg}{$fd} & ( POLLIN|POLLOUT );
      }

      # We have to test separately because kernel doesn't report POLLIN when
      # a pipe gets closed.
      if( $events & (POLLIN|POLLHUP|POLLERR) ) {
         $count++, $watch->[1]->() if defined $watch->[1];
      }

      if( $events & (POLLOUT|POLLPRI|POLLHUP|POLLERR) ) {
         $count++, $watch->[2]->() if defined $watch->[2];
      }

      if( $events & (POLLHUP|POLLERR) ) {
         $count++, $watch->[3]->() if defined $watch->[3];
      }
   }

   # Since we have no way to know if the timeout occurred, we'll have to
   # attempt to fire any waiting timeout events anyway
   $count += $self->_manage_queues;

   alarm( 0 ) if WATCHDOG_ENABLE;

   return $count;
}

sub is_running
{
   my $self = shift;
   return $self->{running};
}

=head2 loop_once

   $count = $loop->loop_once( $timeout )

This method calls the C<poll> method on the stored C<IO::Poll> object,
passing in the value of C<$timeout>, and then runs the C<post_poll> method
on itself. It returns the total number of callbacks invoked by the 
C<post_poll> method, or C<undef> if the underlying C<poll> method returned
an error.

=cut

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   $self->_adjust_timeout( \$timeout );

   $timeout = 0 if FAKE_ISREG_READY and keys %{ $self->{fake_isreg} };

   # Round up to nearest millisecond
   if( $timeout ) {
      my $mils = $timeout * 1000;
      my $fraction = $mils - int $mils;
      $timeout += ( 1 - $fraction ) / 1000 if $fraction;
   }

   if( my $poll = $self->{poll} ) {
      my $pollret;

      $self->pre_wait;
      # There is a bug in IO::Poll at least version 0.07, where poll with no
      # registered masks returns immediately, rather than waiting for a timeout
      # This has been reported: 
      #   http://rt.cpan.org/Ticket/Display.html?id=25049
      if( $poll->handles ) {
         $pollret = $poll->poll( $timeout );

         if( ( $pollret == -1 and $! == EINTR ) or $pollret == 0 
                 and defined $self->{sigproxy} ) {
            # A signal occurred and we have a sigproxy. Allow one more poll
            # call with zero timeout. If it finds something, keep that result.
            # If it finds nothing, keep -1

            # Preserve $! whatever happens
            local $!;

            my $secondattempt = $poll->poll( 0 );
            $pollret = $secondattempt if $secondattempt > 0;
         }
      }
      else {
         # Workaround - we'll use select to fake a millisecond-accurate sleep
         $pollret = select( undef, undef, undef, $timeout );
      }

      $self->post_wait;

      return undef unless defined $pollret;
      return $self->post_poll;
   }
   else {
      my @pollmasks = %{ $self->{pollmask} };

      $self->pre_wait;

      # Perl 5.8.x's IO::Poll::_poll gets confused with no masks
      my $pollret;
      if( @pollmasks ) {
         my $msec = defined $timeout ? $timeout * 1000 : -1;
         $pollret = IO::Poll::_poll( $msec, @pollmasks );
         if( $pollret == -1 and $! == EINTR or
             $pollret == 0 and $self->{sigproxy} ) {
            local $!;

            @pollmasks = %{ $self->{pollmask} };
            my $secondattempt = IO::Poll::_poll( $msec, @pollmasks );
            $pollret = $secondattempt if $secondattempt > 0;
         }

      }
      else {
         # Workaround - we'll use select to fake a millisecond-accurate sleep
         $pollret = select( undef, undef, undef, $timeout );
      }

      $self->post_wait;

      return undef unless defined $pollret;

      $self->{pollevents} = { @pollmasks };
      return $self->post_poll;
   }
}

sub watch_io
{
   my $self = shift;
   my %params = @_;

   $self->__watch_io( %params );

   my $poll = $self->{poll};

   my $handle = $params{handle};
   my $fileno = $handle->fileno;

   my $curmask = $poll ? $poll->mask( $handle )
                       : $self->{pollmask}{$fileno};
   $curmask ||= 0;

   my $mask = $curmask;
   $params{on_read_ready}  and $mask |= POLLIN;
   $params{on_write_ready} and $mask |= POLLOUT | (POLL_CONNECT_POLLPRI ? POLLPRI : 0);
   $params{on_hangup}      and $mask |= POLLHUP;

   if( FAKE_ISREG_READY and S_ISREG +(stat $handle)[2] ) {
      $self->{fake_isreg}{$fileno} = $mask;
   }

   return if $mask == $curmask;

   if( $poll ) {
      $poll->mask( $handle, $mask );
   }
   else {
      $self->{pollmask}{$fileno} = $mask;
   }
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   $self->__unwatch_io( %params );

   my $poll = $self->{poll};

   my $handle = $params{handle};
   my $fileno = $handle->fileno;

   my $curmask = $poll ? $poll->mask( $handle )
                       : $self->{pollmask}{$fileno};
   $curmask ||= 0;

   my $mask = $curmask;
   $params{on_read_ready}  and $mask &= ~POLLIN;
   $params{on_write_ready} and $mask &= ~(POLLOUT | (POLL_CONNECT_POLLPRI ? POLLPRI : 0));
   $params{on_hangup}      and $mask &= ~POLLHUP;

   if( FAKE_ISREG_READY and S_ISREG +(stat $handle)[2] ) {
      if( $mask ) {
         $self->{fake_isreg}{$handle->fileno} = $mask;
      }
      else {
         delete $self->{fake_isreg}{$handle->fileno};
      }
   }

   return if $mask == $curmask;

   if( $poll ) {
      $poll->mask( $handle, $mask );
   }
   else {
      $mask ? ( $self->{pollmask}{$fileno} = $mask )
            : ( delete $self->{pollmask}{$fileno} );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
