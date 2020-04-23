#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Future::Queue;

use strict;
use warnings;

our $VERSION = '0.45';

=head1 NAME

C<Future::Queue> - a FIFO queue of values that uses L<Future>s

=head1 SYNOPSIS

   use Future::Queue;

   my $queue = Future::Queue->new;

   my $f = repeat {
      $queue->shift->then(sub {
         my ( $thing ) = @_;
         ...
      });
   };

   $queue->push( "a thing" );

=head1 DESCRIPTION

Objects in this class provide a simple FIFO queue the stores arbitrary perl
values. Values may be added into the queue using the L</push> method, and
retrieved from it using the L</shift> method.

Values may be stored within the queue object for C<shift> to retrieve later,
or if the queue is empty then the future that C<shift> returns will be
completed once an item becomes available.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $queue = Future::Queue->new

Returns a new C<Future::Queue> instance.

=cut

sub new
{
   my $class = shift;
   return bless {
      items => [],
      waiters => [],
   }, $class;
}

=head2 push

   $queue->push( $item )

Adds a new item into the queue. If the queue was previously empty and there is
at least one C<shift> future waiting, then the next one will be completed by
this method.

=cut

sub push :method
{
   my $self = shift;
   my ( $item ) = @_;

   push @{ $self->{items} }, $item;
   ( shift @{ $self->{waiters} } )->done if @{ $self->{waiters} };
}

=head2 shift

   $item = $queue->shift->get

Returns a C<Future> that will yield the next item from the queue. If there is
already an item then this will be taken and the returned future will be
immediate. If not, then the returned future will be pending, and the next
C<push> method will complete it.

=cut

sub shift :method
{
   my $self = shift;

   if( @{ $self->{items} } ) {
      return Future->done( shift @{ $self->{items} } );
   }

   push @{ $self->{waiters} }, my $f = Future->new;
   return $f->then(sub {
      return Future->done( shift @{ $self->{items} } );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
