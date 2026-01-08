#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

package Future::IO::Impl::Ppoll 0.02;

use v5.20;
use warnings;
use base qw( Future::IO::ImplBase );

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Carp;

use IO::Ppoll qw( POLLIN POLLOUT POLLHUP );
use POSIX qw( SIG_BLOCK sigprocmask );
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

C<Future::IO::Impl::Ppoll> - implement C<Future::IO> using C<ppoll(2)>

=head1 DESCRIPTION

=for highlighter language=perl

This module provides an implementation for L<Future::IO> which uses the
C<ppoll(2)> system call, via L<IO::Ppoll>.

There are no additional methods to use in this module; it simply has to be
loaded, and it will provide the C<Future::IO> implementation methods:

   use Future::IO;
   use Future::IO::Impl::Ppoll;

   my $f = Future::IO->sleep(5);
   ...

Note that the C<waitpid> method will take over the operation of C<$SIG{CHLD}>,
and will print a warning if it discovers some other code has already set it.
Make sure not to otherwise override this signal handler in your program, or
else the C<waitpid> futures will stop working.

=cut

my %fh_by_refaddr;
my %read_futures_by_refaddr;
my %write_futures_by_refaddr;

readonly_struct Alarm => [qw( time f )];
my @alarms;

my $ppoll;
sub ppoll () { $ppoll //= IO::Ppoll->new }

sub _update_poll ( $fh )
{
   my $refaddr = refaddr $fh;
   $fh->fileno or
      carp "Filehandle $fh lost its fileno (was closed?) during poll";

   my $mask = 0;
   $mask |= POLLIN  if scalar ( $read_futures_by_refaddr{$refaddr}  // [] )->@*;
   $mask |= POLLOUT if scalar ( $write_futures_by_refaddr{$refaddr} // [] )->@*;

   ppoll()->mask( $fh => $mask );
   if( $mask ) {
      $fh_by_refaddr{$refaddr} = $fh;
   }
   else {
      delete $fh_by_refaddr{$refaddr};
      delete $read_futures_by_refaddr{$refaddr};
      delete $write_futures_by_refaddr{$refaddr};
   }
}

sub _tick ( $ )
{
   my $ppoll = ppoll();

   my $timeout = undef;
   if( @alarms ) {
      # These are sorted by time order, so head is soonest
      $timeout = $alarms[0]->time - time();
      $timeout = 0 if $timeout < 0;
   }

   $ppoll->poll( $timeout );

   foreach my $refaddr ( keys %fh_by_refaddr ) {
      my $fh = $fh_by_refaddr{$refaddr};
      my $events = $ppoll->events( $fh ) or next;

      if( $events & (POLLIN|POLLHUP) ) {
         my $f = shift $read_futures_by_refaddr{$refaddr}->@*;
         $f and $f->done;
      }
      if( $events & (POLLOUT|POLLHUP) ) {
         my $f = shift $write_futures_by_refaddr{$refaddr}->@*;
         $f and $f->done;
      }

      _update_poll( $fh );
   }

   my $now = time();
   while( @alarms and $alarms[0]->time <= $now ) {
      ( shift @alarms )->f->done;
   }
}

sub alarm ( $class, $time )
{
   my $f = Future::IO::Impl::Ppoll::_Future->new;

   # TODO: Binary search
   my $idx = 0;
   $idx++ while $idx < @alarms and $alarms[$idx]->time < $time;

   splice @alarms, $idx, 0, Alarm( $time, $f );

   $f->on_cancel( sub ( $self ) {
      my $idx = 0;
      $idx++ while $idx < @alarms and $alarms[$idx]->f != $self;

      splice @alarms, $idx, 1, ();
   } );

   return $f;
}

sub sleep ( $class, $secs )
{
   $class->alarm( time() + $secs );
}

sub ready_for_read ( $, $fh )
{
   defined $fh or
      croak "Expected a defined filehandle for ->ready_for_read";

   my $refaddr = refaddr $fh;

   my $futures = $read_futures_by_refaddr{$refaddr} //= [];

   my $f = Future::IO::Impl::Ppoll::_Future->new;

   my $was = scalar @$futures;
   push @$futures, $f;

   return $f if $was;

   _update_poll( $fh );
   return $f;
}

sub ready_for_write ( $, $fh )
{
   defined $fh or
      croak "Expected a defined filehandle for ->ready_for_write";

   my $refaddr = refaddr $fh;

   my $futures = $write_futures_by_refaddr{$refaddr} //= [];

   my $f = Future::IO::Impl::Ppoll::_Future->new;

   my $was = scalar @$futures;
   push @$futures, $f;

   return $f if $was;

   _update_poll( $fh );
   return $f;
}

my $captured_sigchld;
my %waitpid_futures;

sub waitpid ( $, $pid )
{
   unless( $captured_sigchld ) {
      $SIG{CHLD} and $SIG{CHLD} ne "IGNORE" and
         warn "Future::IO::Impl::Ppoll is replacing \$SIG{CHLD}";

      $SIG{CHLD} = sub ( $ ) {
         foreach my $pid ( keys %waitpid_futures ) {
            next unless waitpid( $pid, POSIX::WNOHANG ) > 0;
            my $wstatus = $?;

            my $fs = delete $waitpid_futures{$pid};
            $_->done( $wstatus ) for @$fs;
         }
      };

      $captured_sigchld = 1;

      sigprocmask( SIG_BLOCK, POSIX::SigSet->new( POSIX::SIGCHLD ) );
      # SIGCHLD is now blocked but will be atomically unblocked by the ppoll()
      # operation
   }

   my $f = Future::IO::Impl::Ppoll::_Future->new;

   if( waitpid( $pid, POSIX::WNOHANG ) > 0 ) {
      my $wstatus = $?;
      $f->done( $wstatus );
      return $f;
   }

   push $waitpid_futures{$pid}->@*, $f;

   return $f;
}

package Future::IO::Impl::Ppoll::_Future {
   use base qw( Future );

   sub await ( $self )
   {
      Future::IO::Impl::Ppoll->_tick until $self->is_ready;
      return $self;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
