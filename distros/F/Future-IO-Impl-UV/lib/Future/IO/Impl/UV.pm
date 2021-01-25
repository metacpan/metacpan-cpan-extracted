#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Future::IO::Impl::UV;

use strict;
use warnings;
use base qw( Future::IO::ImplBase );

our $VERSION = '0.01';

use UV;
use UV::Poll;
use UV::Timer;

__PACKAGE__->APPLY;

=head1 NAME

C<Future::IO::Impl::UV> - implement C<Future::IO> using C<UV>

=head1 DESCRIPTION

This module provides an implementation for L<Future::IO> which uses L<UV>.

There are no additional methods to use in this odule; it simply has to be
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

my %watching_read_by_fileno; # {fileno} => [@futures]
my %poll_read_by_fileno;

sub ready_for_read
{
   shift;
   my ( $fh ) = @_;

   my $watching = $watching_read_by_fileno{ $fh->fileno } //= [];

   my $f = Future::IO::Impl::UV::_Future->new;

   my $was = scalar @$watching;
   push @$watching, $f;

   return $f if $was;

   my $poll = $poll_read_by_fileno{ $fh->fileno } =
      UV::Poll->new( fh => $fh );
   $poll->start( UV::Poll::UV_READABLE, sub {
      my ( $self ) = @_;

      $watching->[0]->done;
      shift @$watching;

      $self->stop if !@$watching;
   });

   return $f;
}

my %watching_write_by_fileno; # {fileno} => [@futures]
my %poll_write_by_fileno;

sub ready_for_write
{
   shift;
   my ( $fh ) = @_;

   my $watching = $watching_write_by_fileno{ $fh->fileno } //= [];

   my $f = Future::IO::Impl::UV::_Future->new;

   my $was = scalar @$watching;
   push @$watching, $f;

   return $f if $was;

   my $poll = $poll_write_by_fileno{ $fh->fileno } =
      UV::Poll->new( fh => $fh );
   $poll->start( UV::Poll::UV_WRITABLE, sub {
      my ( $self ) = @_;

      $watching->[0]->done;
      shift @$watching;

      $self->stop if !@$watching;
   });

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
