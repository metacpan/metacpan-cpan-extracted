#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2026 -- leonerd@leonerd.org.uk

package Future::IO::Impl::Glib 0.03;

use v5.14;
use warnings;
use base qw( Future::IO::ImplBase );

use Future::IO qw( POLLIN POLLOUT POLLHUP POLLERR );

use Glib;

__PACKAGE__->APPLY;

=head1 NAME

C<Future::IO::Impl::Glib> - implement C<Future::IO> using C<Glib>

=head1 DESCRIPTION

=for highlighter language=perl

This module provides an implementation for L<Future::IO> which uses L<Glib>.
This is likely the preferred method of providing the API from Glib or Gtk
programs.

There are no additional methods to use in this module; it simply has to be
loaded, and will provide the C<Future::IO> implementation methods:

   use Future::IO;
   use Future::IO::Impl::Glib;

   my $f = Future::IO->sleep(5);
   ...

=cut

sub sleep
{
   shift;
   my ( $secs ) = @_;

   my $f = Future::IO::Impl::Glib::_Future->new;

   my $id = Glib::Timeout->add( $secs * 1000, sub {
      $f->done;
      return 0;
   } );
   $f->on_cancel( sub { Glib::Source->remove( $id ) } );

   return $f;
}

my %read_futures_by_fileno;  # {fileno} => [@futures]
my %write_futures_by_fileno; # {fileno} => [@futures]
my %hup_futures_by_fileno;   # {fileno} => [@futures]

my %revents_map = (
   in  => POLLIN,
   out => POLLOUT,
   hup => POLLHUP,
   err => POLLERR,
);

sub poll
{
   shift;
   my ( $fh, $events ) = @_;

   my $f = Future::IO::Impl::Glib::_Future->new;

   if( $events & POLLIN ) {
      my $futures = $read_futures_by_fileno{ $fh->fileno } //= [];

      my $was = scalar @$futures;
      push @$futures, $f;

      Glib::IO->add_watch( $fh->fileno,
         ['in', 'hup', 'err'],
         sub {
            my ( $id, $ev ) = @_;

            my $revents = 0;
            $revents |= $revents_map{$_} for @$ev;

            $futures->[0]->done( $revents );
            shift @$futures;

            return 1 if scalar @$futures;
            return 0;
         }
      ) if !$was;
   }

   if( $events & POLLOUT ) {
      my $futures = $write_futures_by_fileno{ $fh->fileno } //= [];

      my $was = scalar @$futures;
      push @$futures, $f;

      Glib::IO->add_watch( $fh->fileno,
         ['out', 'hup', 'err'],
         sub {
            my ( $id, $ev ) = @_;

            my $revents = 0;
            $revents |= $revents_map{$_} for @$ev;

            $futures->[0]->done( $revents );
            shift @$futures;

            return 1 if scalar @$futures;
            return 0;
         }
      ) if !$was;
   }

   if( $events & POLLHUP ) {
      my $futures = $hup_futures_by_fileno{ $fh->fileno } //= [];

      my $was = scalar @$futures;
      push @$futures, $f;

      Glib::IO->add_watch( $fh->fileno,
         ['hup', 'err'],
         sub {
            my ( $id, $ev ) = @_;

            my $revents = 0;
            $revents |= $revents_map{$_} for @$ev;

            $futures->[0]->done( $revents );
            shift @$futures;

            return 1 if scalar @$futures;
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

   my $f = Future::IO::Impl::Glib::_Future->new;

   my $id = Glib::Child->watch_add( $pid, sub {
      $f->done( $_[1] );
      return 0;
   } );
   $f->on_cancel( sub { Glib::Source->remove( $id ) } );

   return $f;
}

package Future::IO::Impl::Glib::_Future;
use base qw( Future );

sub await
{
   my $self = shift;
   Glib::MainContext->default->iteration( 1 ) until $self->is_ready;
   return $self;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
