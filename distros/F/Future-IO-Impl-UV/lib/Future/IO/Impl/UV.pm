#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2026 -- leonerd@leonerd.org.uk

package Future::IO::Impl::UV 0.07;

use v5.20;
use warnings;
use base qw( Future::IO::ImplBase );

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Future::IO qw( POLLIN POLLOUT POLLHUP POLLERR );

use UV;
use UV::Poll;
use UV::Timer;
use UV::Signal;

use POSIX ();

use Struct::Dumb qw( readonly_struct );

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

C<Future::IO::Impl::UV> - implement C<Future::IO> using C<UV>

=head1 DESCRIPTION

=for highlighter language=perl

This module provides an implementation for L<Future::IO> which uses L<UV>.

There are no additional methods to use in this module; it simply has to be
loaded, and it will provide the C<Future::IO> implementation methods:

   use Future::IO;
   use Future::IO::Impl::UV;

   my $f = Future::IO->sleep(5);
   ...

=cut

sub sleep ( $, $secs )
{
   my $f = Future::IO::Impl::UV::_Future->new;

   my $timer = UV::Timer->new;
   $timer->start( $secs * 1000, 0, sub ( $ ) { $f->done; } );
   $f->on_cancel( sub ( $ ) { $timer->stop; } );

   return $f;
}

# libuv doesn't like having more than one uv_poll_t instance per filehandle,
# so we'll have to combine reads and writes

readonly_struct Poller => [qw( events f )];
my %pollers_by_refaddr;
my %uvpoll_by_refaddr;

sub _update_poll ( $fh )
{
   my $refaddr = refaddr $fh;

   my $poll = $uvpoll_by_refaddr{$refaddr} //=
      UV::Poll->new(
         fh => $fh,
         on_poll => sub ( $poll, $status, $events ) {
            my $revents = 0;
            $revents |= POLLIN  if $events & UV::Poll::UV_READABLE;
            $revents |= POLLOUT if $events & UV::Poll::UV_WRITABLE;
            $revents |= POLLHUP if $events & UV::Poll::UV_DISCONNECT;
            $revents |= POLLERR if $status;

            my $pollers = $pollers_by_refaddr{$refaddr};
            foreach my $idx ( 0 .. $#$pollers ) {
               $pollers->[$idx]->events & $revents or $revents & (POLLHUP|POLLERR) or
                  next;

               my ( $p ) = splice @$pollers, $idx, 1, ();

               $p and $p->f and $p->f->done( $revents );
               last;
            }

            _update_poll( $fh );
         },
      );

   my $want = 0;
   foreach my $poller ( $pollers_by_refaddr{$refaddr}->@* ) {
      $want |= UV::Poll::UV_READABLE   if $poller->events & POLLIN;
      $want |= UV::Poll::UV_WRITABLE   if $poller->events & POLLOUT;
      $want |= UV::Poll::UV_DISCONNECT if $poller->events & POLLHUP;
   }

   if( $want ) {
      $poll->start( $want );
   }
   else {
      $poll->stop;
      delete $uvpoll_by_refaddr{$refaddr};
      delete $pollers_by_refaddr{$refaddr};
   }
}

sub poll ( $, $fh, $events )
{
   my $refaddr = refaddr $fh;

   my $f = Future::IO::Impl::UV::_Future->new;

   push $pollers_by_refaddr{$refaddr}->@*, Poller( $events, $f );

   _update_poll( $fh );
   return $f;
}

my $sigchld_watch;
my %futures_waitpid; # {$pid} => [@futures]

sub waitpid ( $, $pid )
{
   # libuv does not currently have a nice way to ask it to watch an existing
   # PID that it didn't fork/exec itself. All we can do here is ask to be
   # informed of SIGCHLD and then check if any of the processes we're keeping
   # an eye on have exited yet. This is kindof sucky, because it means a
   # linear scan on every signal.
   #   https://github.com/libuv/libuv/issues/3100
   $sigchld_watch ||= do {
      my $w = UV::Signal->new( signal => POSIX::SIGCHLD );
      $w->start(sub ( $, $signum ) {
         foreach my $pid ( keys %futures_waitpid ) {
            next unless waitpid( $pid, POSIX::WNOHANG ) > 0;
            my $wstatus = $?;

            my $fs = delete $futures_waitpid{$pid};
            $_->done( $wstatus ) for @$fs;
         }
      });
      $w;
   };

   my $f = Future::IO::Impl::UV::_Future->new;

   if( waitpid( $pid, POSIX::WNOHANG ) > 0 ) {
      my $wstatus = $?;
      $f->done( $wstatus );
      return $f;
   }

   push $futures_waitpid{$pid}->@*, $f;

   return $f;
}

package Future::IO::Impl::UV::_Future;
use base qw( Future );

sub await ( $self )
{
   UV::loop->run( UV::Loop::UV_RUN_ONCE ) until $self->is_ready;
   return $self;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
