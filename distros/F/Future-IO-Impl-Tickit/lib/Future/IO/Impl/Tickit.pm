#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2026 -- leonerd@leonerd.org.uk

package Future::IO::Impl::Tickit 0.02;

use v5.14;
use warnings;
use base qw( Future::IO::ImplBase );

use Carp;

__PACKAGE__->APPLY;

use Future::IO qw( POLLIN POLLOUT POLLHUP POLLERR );
use Tickit;
my $tickit;

=head1 NAME

C<Future::IO::Impl::Tickit> - implement C<Future::IO> with C<Tickit>

=head1 SYNOPSIS

=for highlighter language=perl

   use Future::IO;
   use Future::IO::Impl::Tickit;

   use Tickit;

   my $tickit = Tickit->new;
   Future::IO::Impl::Tickit->set_tickit( $tickit );

   ...

=head1 DESCRIPTION

This module provides an implementation for L<Future::IO> which uses L<Tickit>.

Because this module will need a valid toplevel C<Tickit> instance object in
order to work, you will need to call the L</set_tickit> method before any of
the C<Future::IO> interface will work.

=cut

=head1 METHODS

=cut

=head2 set_tickit

   Future::IO::Impl::Tickit->set_tickit( $tickit );

Sets the toplevel C<Tickit> instance to use for the event watching used to
implement this module.

=cut

sub set_tickit
{
   shift;

   $tickit and $tickit != $_[0] and
      croak "A Tickit instance was alraedy set by ->set_tickit; cannot set another";

   $tickit = $_[0];
}

sub sleep
{
   shift;
   my ( $secs ) = @_;

   $tickit or
      croak "Need a Tickit instance with ->set_tickit before calling Future::IO->sleep";

   my $f = Future::IO::Impl::Tickit::_Future->new;

   my $id = $tickit->watch_timer_after( $secs, sub {
      $f->done;
   } );
   $f->on_cancel( sub { $tickit->watch_cancel( $id ) } );

   return $f;
}

# for POLLIN or POLLHUP
my %read_watch_by_fileno;   # {fileno} => $watch
my %read_futures_by_fileno; # {fileno} => [@futures]

# for POLLOUT
my %write_watch_by_fileno;   # {fileno} => $watch
my %write_futures_by_fileno; # {fileno} => [@futures]

sub poll
{
   shift;
   my ( $fh, $events ) = @_;
   my $fd = $fh->fileno;

   $tickit or
      croak "Need a Tickit instance with ->set_tickit before calling Future::IO->poll";

   my $f = Future::IO::Impl::Tickit::_Future->new;

   if( $events & (POLLIN|POLLHUP) ) {
      my $futures = $read_futures_by_fileno{ $fd } //= [];

      my $was = scalar @$futures;
      push @$futures, $f;

      my $cond = 0;
      $cond |= Tickit::IO_IN  if $events & POLLIN;
      $cond |= Tickit::IO_HUP if $events & POLLHUP;

      $read_watch_by_fileno{ $fd } = $tickit->watch_io( $fh, $cond,
         sub {
            my ( $info ) = @_;

            my $revents = 0;
            $revents |= POLLIN  if $info->cond & Tickit::IO_IN;
            $revents |= POLLHUP if $info->cond & Tickit::IO_HUP;
            $revents |= POLLERR if $info->cond & Tickit::IO_ERR;
            $futures->[0]->done( $revents );
            shift @$futures;

            return 1 if scalar @$futures;

            $tickit->watch_cancel( delete $read_watch_by_fileno{ $fd } );
            return 0;
         }
      ) if !$was;
   }

   if( $events & POLLOUT ) {
      my $futures = $write_futures_by_fileno{ $fd } //= [];

      my $was = scalar @$futures;
      push @$futures, $f;

      $write_watch_by_fileno{ $fd } = $tickit->watch_io( $fh, Tickit::IO_OUT|Tickit::IO_HUP,
         sub {
            my ( $info ) = @_;

            my $revents = 0;
            $revents |= POLLOUT if $info->cond & Tickit::IO_OUT;
            $revents |= POLLHUP if $info->cond & Tickit::IO_HUP;
            $revents |= POLLERR if $info->cond & Tickit::IO_ERR;
            $futures->[0]->done( $revents );
            shift @$futures;

            return 1 if scalar @$futures;

            $tickit->watch_cancel( delete $write_watch_by_fileno{ $fd } );
            return 0;
         }
      ) if !$was;
   }

   return $f;
}

sub waitpid
{
   shift;
   my ( $pid ) = @_;

   $tickit or
      croak "Need a Tickit instance with ->set_tickit before calling Future::IO->waitpid";

   my $f = Future::IO::Impl::Tickit::_Future->new;

   my $id = $tickit->watch_process( $pid, sub {
      my ( $info ) = @_;
      $f->done( $info->wstatus );
   } );
   $f->on_cancel( sub { $tickit->watch_cancel( $id ) } );

   return $f;
}

package Future::IO::Impl::Tickit::_Future {
   use base qw( Future );

   sub await
   {
      my $self = shift;
      $tickit->tick until $self->is_ready;
      return $self;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
