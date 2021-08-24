#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2021 -- leonerd@leonerd.org.uk

package Future::IO::Impl::Glib 0.02;

use v5.14;
use warnings;
use base qw( Future::IO::ImplBase );

use Glib;

__PACKAGE__->APPLY;

=head1 NAME

C<Future::IO::Impl::Glib> - implement C<Future::IO> using C<Glib>

=head1 DESCRIPTION

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

my %read_futures_by_fileno; # {fileno} => [@futures]

sub ready_for_read
{
   shift;
   my ( $fh ) = @_;

   my $futures = $read_futures_by_fileno{ $fh->fileno } //= [];

   my $f = Future::IO::Impl::Glib::_Future->new;

   my $was = scalar @$futures;
   push @$futures, $f;

   return $f if $was;

   Glib::IO->add_watch( $fh->fileno,
      ['in', 'hup', 'err'],
      sub {
         $futures->[0]->done;
         shift @$futures;

         return 1 if scalar @$futures;
         return 0;
      }
   );

   return $f;
}

my %write_futures_by_fileno;

sub ready_for_write
{
   shift;
   my ( $fh ) = @_;

   my $futures = $write_futures_by_fileno{ $fh->fileno } //= [];

   my $f = Future::IO::Impl::Glib::_Future->new;

   my $was = scalar @$futures;
   push @$futures, $f;

   return $f if $was;

   Glib::IO->add_watch( $fh->fileno,
      ['out', 'hup', 'err'],
      sub {
         $futures->[0]->done;
         shift @$futures;

         return 1 if scalar @$futures;
         return 0;
      }
   );

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
