#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2026 -- leonerd@leonerd.org.uk

package Future::IO::Impl::Tickit 0.05;

use v5.20;
use warnings;
use base qw( Future::IO::ImplBase );

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Carp;

__PACKAGE__->APPLY;

use Future::IO 0.20 qw( POLLIN POLLOUT POLLPRI POLLHUP POLLERR );
use Struct::Dumb qw( readonly_struct );
use Tickit 0.75;  # Tickit::IO_PRI
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

sub set_tickit ( $, $new_tickit )
{
   $tickit and $tickit != $new_tickit and
      croak "A Tickit instance was alraedy set by ->set_tickit; cannot set another";

   $tickit = $new_tickit;

   # We don't have a constructor method so now's about the best time
   $SIG{PIPE} = 'IGNORE';
}

sub sleep ( $, $secs )
{
   $tickit or
      croak "Need a Tickit instance with ->set_tickit before calling Future::IO->sleep";

   my $f = Future::IO::Impl::Tickit::_Future->new;

   my $id = $tickit->watch_timer_after( $secs, sub () {
      $f->done;
   } );
   $f->on_cancel( sub ( $ ) { $tickit->watch_cancel( $id ) } );

   return $f;
}

readonly_struct Poller => [qw( events f )];
my %pollers_by_fileno;
my %watches_by_fileno; # {fileno} => [$watch, $events]

sub poll ( $, $fh, $events )
{
   my $fd = $fh->fileno;

   $tickit or
      croak "Need a Tickit instance with ->set_tickit before calling Future::IO->poll";

   my $f = Future::IO::Impl::Tickit::_Future->new;

   my $pollers = $pollers_by_fileno{$fh->fileno} //= [];
   push @$pollers, Poller( $events, $f );

   _update_io( $fh );

   $f->on_cancel( sub {
      my $self = shift;

      # Cancelling poll futures is pretty rare so this doesn't have to be that
      # performant
      my $idx;
      $pollers->[$_]->f == $self and
         $idx = $_, last for 0 .. $#$pollers;

      defined $idx and
         splice @$pollers, $idx, 1, ();

      _update_io( $fh );
   });

   return $f;
}

sub _update_io ( $fh )
{
   my $fileno = $fh->fileno;

   my $want_events = 0;
   $want_events |= $_->events for ( my $pollers = $pollers_by_fileno{$fileno} )->@*;

   return if $watches_by_fileno{$fileno} and $watches_by_fileno{$fileno}[1] == $want_events;

   # First cancel the old one
   if( $watches_by_fileno{$fileno} ) {
      $tickit->watch_cancel( $watches_by_fileno{$fileno}[0] );
   }

   my $cond = 0;
   $cond |= Tickit::IO_IN  if $want_events & POLLIN;
   $cond |= Tickit::IO_OUT if $want_events & POLLOUT;
   $cond |= Tickit::IO_PRI if $want_events & POLLPRI;

   unless( $cond ) {
      delete $watches_by_fileno{$fileno};
      return;
   }

   my $watch = $tickit->watch_io( $fh, $cond,
      sub ( $info ) {
         my $revents = 0;
         $revents |= POLLIN  if $info->cond & Tickit::IO_IN;
         $revents |= POLLOUT if $info->cond & Tickit::IO_OUT;
         $revents |= POLLPRI if $info->cond & Tickit::IO_PRI;
         $revents |= POLLHUP if $info->cond & Tickit::IO_HUP;
         $revents |= POLLERR if $info->cond & Tickit::IO_ERR;

         # Find the next poller which cares about at least one of these events
         foreach my $idx ( 0 .. $#$pollers ) {
            my $want_revents = $revents & ( $pollers->[$idx]->events | POLLHUP|POLLERR )
               or next;

            my ( $poller ) = splice @$pollers, $idx, 1, ();

            $poller and $poller->f and $poller->f->done( $want_revents );
            last;
         }

         if( !@$pollers ) {
            my ( $watch ) = ( delete $watches_by_fileno{$fileno} )->@*;
            $tickit->watch_cancel( $watch );
            return 0;
         }

         _update_io( $fh );
         return 1;
      }
   );

   $watches_by_fileno{$fileno} = [ $watch, $want_events ];
}

sub waitpid ( $, $pid )
{
   $tickit or
      croak "Need a Tickit instance with ->set_tickit before calling Future::IO->waitpid";

   my $f = Future::IO::Impl::Tickit::_Future->new;

   my $id = $tickit->watch_process( $pid, sub ( $info ) {
      $f->done( $info->wstatus );
   } );
   $f->on_cancel( sub ( $ ) { $tickit->watch_cancel( $id ) } );

   return $f;
}

package Future::IO::Impl::Tickit::_Future {
   use base qw( Future );

   sub await ( $self )
   {
      $tickit->tick until $self->is_ready;
      return $self;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
