#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Future::IO::Impl::UV 0.02;

use v5.14;
use warnings;
use base qw( Future::IO::ImplBase );

use UV;
use UV::Poll;
use UV::Timer;
use UV::Signal;

use POSIX ();

__PACKAGE__->APPLY;

=head1 NAME

C<Future::IO::Impl::UV> - implement C<Future::IO> using C<UV>

=head1 DESCRIPTION

This module provides an implementation for L<Future::IO> which uses L<UV>.

There are no additional methods to use in this module; it simply has to be
loaded, and it will provide the C<Future::IO> implementation methods:

   use Future::IO;
   use Future::IO::Impl::UV;

   my $f = Future::IO->sleep(5);
   ...

=cut

sub sleep
{
   shift;
   my ( $secs ) = @_;

   my $f = Future::IO::Impl::UV::_Future->new;

   my $timer = UV::Timer->new;
   $timer->start( $secs * 1000, 0, sub { $f->done; } );
   $f->on_cancel( sub { $timer->stop; } );

   return $f;
}

my %read_futures_by_fileno; # {fileno} => [@futures]
my %poll_read_by_fileno;

sub ready_for_read
{
   shift;
   my ( $fh ) = @_;

   my $futures = $read_futures_by_fileno{ $fh->fileno } //= [];

   my $f = Future::IO::Impl::UV::_Future->new;

   my $was = scalar @$futures;
   push @$futures, $f;

   return $f if $was;

   my $poll = $poll_read_by_fileno{ $fh->fileno } =
      UV::Poll->new( fh => $fh );
   $poll->start( UV::Poll::UV_READABLE, sub {
      my ( $self ) = @_;

      $futures->[0]->done;
      shift @$futures;

      $self->stop if !@$futures;
   });

   return $f;
}

my %write_futures_by_fileno; # {fileno} => [@futures]
my %poll_write_by_fileno;

sub ready_for_write
{
   shift;
   my ( $fh ) = @_;

   my $futures = $write_futures_by_fileno{ $fh->fileno } //= [];

   my $f = Future::IO::Impl::UV::_Future->new;

   my $was = scalar @$futures;
   push @$futures, $f;

   return $f if $was;

   my $poll = $poll_write_by_fileno{ $fh->fileno } =
      UV::Poll->new( fh => $fh );
   $poll->start( UV::Poll::UV_WRITABLE, sub {
      my ( $self ) = @_;

      $futures->[0]->done;
      shift @$futures;

      $self->stop if !@$futures;
   });

   return $f;
}

my $sigchld_watch;
my %futures_waitpid; # {$pid} => [@futures]

sub waitpid
{
   shift;
   my ( $pid ) = @_;

   # libuv does not currently have a nice way to ask it to watch an existing
   # PID that it didn't fork/exec itself. All we can do here is ask to be
   # informed of SIGCHLD and then check if any of the processes we're keeping
   # an eye on have exited yet. This is kindof sucky, because it means a
   # linear scan on every signal.
   #   https://github.com/libuv/libuv/issues/3100
   $sigchld_watch ||= do {
      my $w = UV::Signal->new( signal => POSIX::SIGCHLD );
      $w->start(sub {
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

   push @{ $futures_waitpid{$pid} }, $f;

   return $f;
}

package Future::IO::Impl::UV::_Future;
use base qw( Future );

sub await
{
   my $self = shift;
   UV::loop->run( UV::Loop::UV_RUN_ONCE ) until $self->is_ready;
   return $self;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
