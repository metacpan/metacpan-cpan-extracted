#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

package Future::IO::Impl::KQueue 0.03;

use v5.20;
use warnings;
use base qw( Future::IO::ImplBase );
use Future::IO qw( POLLIN POLLOUT POLLPRI POLLHUP POLLERR POLLNVAL );

Future::IO::ImplBase->VERSION( '0.22' );

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Carp;
our @CARP_NOT = qw( Future::IO::Impl::KQueue::_Future );

use IO::KQueue;
use POSIX ();
use Struct::Dumb qw( readonly_struct );
use Time::HiRes qw( time );

BEGIN {
   if( $^V ge v5.36 ) {
      builtin->import(qw( refaddr ));
      warnings->unimport(qw( experimental::builtin )) if $^V lt v5.40;
   }
   else {
      require Scalar::Util;
      Scalar::Util->import(qw( refaddr ));
   }
}

__PACKAGE__->APPLY;

=head1 NAME

C<Future::IO::Impl::KQueue> - implement C<Future::IO> using C<kqueue(2)>

=head1 DESCRIPTION

=for highlighter language=perl

This module provides an implementation for L<Future::IO> which uses the
C<kqueue(2)> and C<kevents(2)> system calls, via L<IO::KQueue>.

There are no additional methods to use in this module; it simply has to be
loaded, and it will provide the C<Future::IO> implementation methods:

   use Future::IO;
   use Future::IO::Impl::KQueue;

   my $f = Future::IO->sleep(5);
   ...

=cut

readonly_struct Poller => [qw( events f )];
my %pollers_by_refaddr;
my @deferred_epipe;

my %waitpids_by_pid;

my $kq;
sub kqueue () { $kq //= IO::KQueue->new; }

sub _new_future ( $ ) { return Future::IO::Impl::KQueue::_Future->new }

sub _tick ( $class )
{
   kqueue();

   my $timeout = $class->_timeout;

   $timeout = 0 if @deferred_epipe;

   # $timeout in msec
   my @events = $kq->kevent( defined $timeout ? $timeout * 1000 : undef );

   foreach my $e ( @events ) {
      my $filter = $e->[KQ_FILTER];

      if( $filter == EVFILT_READ or $filter == EVFILT_WRITE ) {
         my $refaddr = $e->[KQ_UDATA];

         my $revents = ( $filter == EVFILT_READ )  ? POLLIN :
                       ( $filter == EVFILT_WRITE ) ? POLLOUT : 0;
         $revents |= POLLHUP if $e->[KQ_FLAGS] & EV_EOF;

         my $pollers = $pollers_by_refaddr{$refaddr} or next;
         # TODO: if nobody cared, maybe we should remove it?

         # Find the next poller which cares about at least one of these events
         foreach my $idx ( 0 .. $#$pollers ) {
            my $want_revents = $revents & ( $pollers->[$idx]->events | POLLHUP|POLLERR|POLLNVAL )
               or next;

            my ( $poller ) = splice @$pollers, $idx, 1, ();

            $poller and $poller->f and $poller->f->done( $want_revents );
            last;
         }

         my $mask = 0;
         $mask |= $_->events for ( $pollers_by_refaddr{$refaddr} // [] )->@*;

         if( $filter == EVFILT_READ and not $mask & (POLLIN|POLLPRI) ) {
            $kq->EV_SET( $e->[KQ_IDENT], EVFILT_READ, EV_DELETE );
         }
         if( $filter == EVFILT_WRITE and not $mask & POLLOUT ) {
            $kq->EV_SET( $e->[KQ_IDENT], EVFILT_WRITE, EV_DELETE );
         }
      }
      elsif( $filter == EVFILT_SIGNAL ) {
         my $signum = $e->[KQ_IDENT];
         if( $signum == POSIX::SIGCHLD ) {
            foreach my $pid ( keys %waitpids_by_pid ) {
               next unless waitpid( $pid, POSIX::WNOHANG ) > 0;
               my $wstatus = $?;

               my $fs = delete $waitpids_by_pid{$pid};
               $_->done( $wstatus ) for @$fs;
            }
         }
      }
      else {
         die "Oopsie event filter=$filter <@$e>";
      }
   }

   $class->_manage_timers;

   if( @deferred_epipe ) {
      my @f = @deferred_epipe; @deferred_epipe = ();
      foreach my $f ( @f ) {
         $f->done( POLLHUP );
      }
   }
}

# We can't use KQueue's EVFILT_TIMER for sleep() and alarm() because timeout
# values would have to be unique. It can't support multiple separate timers
# with the exact same expiry time :(
# Instead we just use the timer queue supplied by Future::IO::ImplBase 0.22

sub poll ( $, $fh, $events )
{
   defined $fh or
      croak "Expected a defined filehandle for ->poll";

   kqueue();

   my $refaddr = refaddr $fh;

   my $pollers = $pollers_by_refaddr{$refaddr} //= [];

   my $f = Future::IO::Impl::KQueue::_Future->new;

   defined( my $fileno = $fh->fileno ) or
      carp "Filehandle $fh lost its fileno (was closed?) during poll";

   my $mask = $events;
   $mask |= $_->events for ( $pollers_by_refaddr{$refaddr} // [] )->@*;

   my $got_epipe;

   # Don't have to ask for POLLHUP; it comes for free
   # We should always use the _READ filter if looking for HUP though
   if( $mask & POLLHUP ) {
      $mask |= POLLIN;
      $mask &= ~POLLHUP;
   }

   if( $mask & (POLLIN|POLLPRI) ) {
      # POLLPRI doesn't have a direct KQueue equivalent
      eval { $kq->EV_SET( $fileno, EVFILT_READ, EV_ADD, 0, 0, $refaddr ); 1 } or
         ( $! == POSIX::EPIPE and ++$got_epipe ) or
         die $@;
   }
   if( $mask & POLLOUT ) {
      eval { $kq->EV_SET( $fileno, EVFILT_WRITE, EV_ADD, 0, 0, $refaddr ); 1 } or
         ( $! == POSIX::EPIPE and ++$got_epipe ) or
         die $@;
   }
   if( $mask & ~(POLLIN|POLLOUT|POLLPRI) ) {
      croak sprintf "ARGH unrecognised event flags mask %02X", $mask;
   }

   if( $got_epipe ) {
      # EV_SET yielded EPIPE synchronously. We need to defer this reporting
      # until the next call to _tick.
      push @deferred_epipe, $f;
   }
   else {
      push @$pollers, Poller( $events, $f );
   }

   return $f;
}

# We can't use IO::KQueue's EVFILT_PROC here because of a small bug. KQueue.xs
# defines the `fflags` field as u_short rather than u_int, which means it
# truncates the `NOTE_EXIT` flag which we'd need to have access to.
# I would report that upstream, but the repo is currently marked readonly and
# seems abandoned. :(
#
# For now we'll just use the usual SIGCHLD wrapper trick from Ppoll.

my $captured_sigchld;

sub waitpid ( $, $pid )
{
   unless( $captured_sigchld ) {
      $SIG{CHLD} and $SIG{CHLD} ne "IGNORE" and
         warn "Future::IO::Impl::KQueue is replacing \$SIG{CHLD}";

      kqueue();

      $kq->EV_SET( POSIX::SIGCHLD, EVFILT_SIGNAL, EV_ADD );

      $captured_sigchld = 1;
   }

   my $f = Future::IO::Impl::KQueue::_Future->new;

   if( waitpid( $pid, POSIX::WNOHANG ) > 0 ) {
      my $wstatus = $?;
      $f->done( $wstatus );
      return $f;
   }

   push $waitpids_by_pid{$pid}->@*, $f;

   return $f;
}

package Future::IO::Impl::KQueue::_Future {
   use base qw( Future );

   sub await ( $self )
   {
      Future::IO::Impl::KQueue->_tick until $self->is_ready;
      return $self;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
