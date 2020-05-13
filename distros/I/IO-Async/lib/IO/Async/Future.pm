#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package IO::Async::Future;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( Future );
Future->VERSION( '0.05' ); # to respect subclassing

use Carp;

=head1 NAME

C<IO::Async::Future> - use L<Future> with L<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new;

 my $future = $loop->new_future;

 $loop->watch_time( after => 3, code => sub { $future->done( "Done" ) } );

 print $future->get, "\n";

=head1 DESCRIPTION

This subclass of L<Future> stores a reference to the L<IO::Async::Loop>
instance that created it, allowing the C<await> method to block until the
Future is ready. These objects should not be constructed directly; instead
the C<new_future> method on the containing Loop should be used.

For a full description on how to use Futures, see the L<Future> documentation.

=cut

=head1 CONSTRUCTORS

New C<IO::Async::Future> objects should be constructed by using the following
methods on the C<Loop>. For more detail see the L<IO::Async::Loop>
documentation.

   $future = $loop->new_future

Returns a new pending Future.

   $future = $loop->delay_future( %args )

Returns a new Future that will become done at a given time.

   $future = $loop->timeout_future( %args )

Returns a new Future that will become failed at a given time.

=cut

sub new
{
   my $proto = shift;
   my $self = $proto->SUPER::new;

   if( ref $proto ) {
      $self->{loop} = $proto->{loop};
   }
   else {
      $self->{loop} = shift;
   }

   return $self;
}

=head1 METHODS

=cut

=head2 loop

   $loop = $future->loop

Returns the underlying L<IO::Async::Loop> object.

=cut

sub loop
{
   my $self = shift;
   return $self->{loop};
}

sub await
{
   my $self = shift;
   $self->{loop}->await( $self );
}

=head2 done_later

   $future->done_later( @result )

A shortcut to calling the C<done> method in a C<later> idle watch on the
underlying Loop object. Ensures that a returned Future object is not ready
immediately, but will wait for the next IO round.

Like C<done>, returns C<$future> itself to allow easy chaining.

=cut

sub done_later
{
   my $self = shift;
   my @result = @_;

   $self->loop->later( sub { $self->done( @result ) } );

   return $self;
}

=head2 fail_later

   $future->fail_later( $exception, @details )

A shortcut to calling the C<fail> method in a C<later> idle watch on the
underlying Loop object. Ensures that a returned Future object is not ready
immediately, but will wait for the next IO round.

Like C<fail>, returns C<$future> itself to allow easy chaining.

=cut

sub fail_later
{
   my $self = shift;
   my ( $exception, @details ) = @_;

   $exception or croak "Expected a true exception";

   $self->loop->later( sub { $self->fail( $exception, @details ) } );

   return $self;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
