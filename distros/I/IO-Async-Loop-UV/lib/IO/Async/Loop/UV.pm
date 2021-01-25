#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2021 -- leonerd@leonerd.org.uk

package IO::Async::Loop::UV;

use strict;
use warnings;

use Carp;

our $VERSION = '0.02';
use constant API_VERSION => '0.49';

# We cannot support ->watch_process( 0 => ... ) because libuv does not give us
# a hook
use constant _CAN_WATCH_ALL_PIDS => 0;

use base qw( IO::Async::Loop );
IO::Async::Loop->VERSION( '0.49' );

use UV;
use UV::Idle;
use UV::Loop;
use UV::Poll;
use UV::Signal;
use UV::Timer;

=head1 NAME

C<IO::Async::Loop::UV> - use C<IO::Async> with C<UV>

=head1 SYNOPSIS

 use IO::Async::Loop::UV;

 my $loop = IO::Async::Loop::UV->new();

 $loop->add( ... );

 $loop->add( IO::Async::Signal->new(
       name => 'HUP',
       on_receipt => sub { ... },
 ) );

 $loop->loop_forever();

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses L<UV> to perform its work.

As both C<UV> and the underlying F<libuv> are quite new, this module currently
has a few shortcomings and limitations. See the L</BUGS> section.

=cut

sub new
{
   my $class = shift;
   my $self = $class->SUPER::__new( @_ );

   $self->{fakefiles} = {};

   return $self;
}

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   $timeout = 0 if keys %{ $self->{idles} };

   my $timer;
   my $mode = UV::Loop::UV_RUN_ONCE;
   if( defined $timeout and $timeout == 0 ) {
      $mode = UV::Loop::UV_RUN_NOWAIT;
   }
   elsif( defined $timeout and $timeout > 0 ) {
      $timer = UV::Timer->new;
      $timer->start( $timeout * 1000, 0, sub {} );
   }

   UV::loop->run( $mode );

   $timer->stop if $timer;
}

sub watch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";
   my $state = $self->{fh}{$handle} ||= {
      mask => 0,
   };

   if( my $on_read_ready = $params{on_read_ready} ) {
      $state->{on_read_ready} = $on_read_ready;
      $state->{mask} |= UV::Poll::UV_READABLE;
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $state->{on_write_ready} = $on_write_ready;
      $state->{mask} |= UV::Poll::UV_WRITABLE;
   }

   if( ( stat $handle ) and -f _ ) {
      my $fakefiles = $self->{fakefiles};
      ( $self->{fakefiles_idle} //= UV::Idle->new(
         on_idle => sub {
            foreach my $fake ( values %$fakefiles ) {
               $fake->{on_read_ready}->()  if $fake->{on_read_ready};
               $fake->{on_write_ready}->() if $fake->{on_write_ready};
            }
         }
      ) )->start;

      $self->{fakefiles}{$handle} = $state;
   }
   else {
      # UV has a thing it calls "handles". They're not filehandles, they're
      # something else
      my $uvh = $state->{uvh} ||= UV::Poll->new( fd => $handle->fileno );
      my $cb = $self->{fh_cb}{$handle} ||= sub {
         my ( undef, $status, $events ) = @_;
         if( my $cb = $state->{on_read_ready} ) {
            $cb->() if $events & UV::Poll::UV_READABLE or $status < 0;
         }
         if( my $cb = $state->{on_write_ready} ) {
            $cb->() if $events & UV::Poll::UV_WRITABLE or $status < 0;
         }
      };

      $uvh->start( $state->{mask}, $cb );
   }
}

sub unwatch_io
{
   my $self = shift;
   my %params = @_;

   my $handle = $params{handle} or die "Need a handle";
   my $state = $self->{fh}{$handle} or return;
   my $uvh = $state->{uvh};

   if( $params{on_read_ready} ) {
      $state->{mask} &= ~UV::Poll::UV_READABLE;
      undef $state->{on_read_ready};
   }

   if( $params{on_write_ready} ) {
      $state->{mask} &= ~UV::Poll::UV_WRITABLE;
      undef $state->{on_write_ready};
   }

   if( !$uvh ) {
      if( $state->{mask} ) {
         # do nothing
      }
      else {
         delete $self->{fakefiles}{$handle};
         $self->{fakefiles_idle}->stop unless keys %{ $self->{fakefiles} };
      }
   }
   else {
      if( $state->{mask} ) {
         $uvh->start( $state->{mask}, $self->{fh_cb}{$handle} );
      }
      else {
         delete $self->{fh}{$handle};
         delete $self->{fh_cb}{$handle};
         $uvh->stop;
      }
   }
}

sub watch_time
{
   my $self = shift;
   my %params = @_;

   my $code = $params{code} or croak "Expected 'code' as CODE ref";
   my $now = $params{now} || $self->time;
   my $delay = $params{after} || ( $params{at} - $now );

   $delay = 0 if $delay < 0;

   my $timer = UV::Timer->new;
   # Ugly selfcycle to avoid it going out of scope and getting DESTROY'ed
   $timer->start( $delay * 1000, 0, sub {
      undef $timer;
      $code->();
   });

   return $timer;
}

sub unwatch_time
{
   my $self = shift;
   my ( $timer ) = @_;

   $timer->stop;
}

sub watch_idle
{
   my $self = shift;
   my %params = @_;

   my $when = delete $params{when} or croak "Expected 'when'";

   my $code = delete $params{code} or croak "Expected 'code' as a CODE ref";

   $when eq "later" or croak "Expected 'when' to be 'later'";

   my $idles = $self->{idles} ||= {};
   my $idle = UV::Idle->new;
   $idles->{$idle}++;
   $idle->start( sub {
      $idle->stop;
      delete $idles->{$idle};
      $code->();
   } );

   return $idle;
}

sub unwatch_idle
{
   my $self = shift;
   my ( $idle ) = @_;

   $idle->stop;
   delete $self->{idles}{$idle};
}

sub watch_signal
{
   my $self = shift;
   my ( $signame, $code ) = @_;

   defined( my $signum = IO::Async::OS->signame2num( $signame ) ) or
      croak "Unrecognised signal $signame";

   my $signals = $self->{signals} ||= {};
   my $signal = UV::Signal->new( signal => $signum );
   $signal->start( $code );

   $signals->{$signame} = $signal;
}

sub unwatch_signal
{
   my $self = shift;
   my ( $signame ) = @_;

   ( delete $self->{signals}{$signame} )->stop;
}

sub watch_process
{
   my $self = shift;
   my ( $pid, $code ) = @_;

   defined $pid or croak "Require a PID for ->watch_process";
   $pid or croak "Require a PID for ->watch_process (cannot watch for all processes by PID=0)";

   my $pids = $self->{pids} ||= {};
   # libuv does not currently have a nice way to ask it to watch an existing
   # PID that it didn't fork/exec itself. All we can do here is ask to be
   # informed of SIGCHLD and then check if any of the processes we're keeping
   # an eye on have exited yet. This is kindof sucky, because it means a
   # linear scan on every signal.
   #   https://github.com/libuv/libuv/issues/3100
   $self->{sigchld_watch} ||= do {
      my $sigchld_watch = UV::Signal->new( signal => POSIX::SIGCHLD );
      $sigchld_watch->start(sub {
         foreach my $pid ( keys %$pids ) {
            my $zid = waitpid( $pid, POSIX::WNOHANG ) or next;
            next if $zid == -1;
            my $status = $?;

            ( delete $pids->{$pid} )->( $zid, $status );
         }
      });
      $sigchld_watch;
   };

   # There's a chance the process already exit()ed before we watched for
   # SIGCHLD
   my $zid;
   if( $zid = waitpid( $pid, POSIX::WNOHANG ) and $zid != -1 ) {
      my $status = $?;
      $code->( $zid, $status );

      return;
   }

   $pids->{$pid} = $code;
}

sub unwatch_process
{
   my $self = shift;
   my ( $pid ) = @_;

   delete $self->{pids}{$pid};
}

=head1 BUGS

=over 2

=item *

F<libuv> does not provide a way to inspect the C<POLLHUP> status bit, so some
types of file descriptor cannot provide EOF condition. This causes a unit-test
failure. (RT#113010)

=item *

L<libuv> does not provide a way to be informed of any SIGCHLD/waitpid()
status. Because of this there is no ability to watch for all processes by

   $loop->watch_process( 0 => sub { ... } );

Attempts to do this will throw an exception.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
