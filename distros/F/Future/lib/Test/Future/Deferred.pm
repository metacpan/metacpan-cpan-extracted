#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Test::Future::Deferred;

use strict;
use warnings;
use base qw( Future );

our $VERSION = '0.45';

=head1 NAME

C<Test::Future::Deferred> - a future which completes later

 my $future = Test::Future::Deferred->done_later( 1, 2, 3 );

 # Future is not ready yet

 my @result = $future->get;

=head1 DESCRIPTION

This subclass of L<Future> provides two new methods and an implementation of
the C<await> interface, which allows the futures to appear pending at first,
but then to complete when C<get> is called at the toplevel on one of them.

This behaviour is useful in unit tests to check that behaviour of a module
under test is correct even with non-immediate futures, as it allows a future
to easily be constructed that will complete "soon", but not yet, without
needing an event loop.

Because these futures provide their own C<await> method, they shouldn't be
mixed in the same program with other kinds of futures from real event systems
or similar.

=cut

my @deferrals;

sub await
{
   while( my $d = shift @deferrals ) {
      my ( $f, $method, @args ) = @$d;
      $f->$method( @args );
   }
   # TODO: detect if still not done with no more deferrals
}

=head1 METHODS

=cut

=head2 done_later

   $f->done_later( @args )

Equivalent to invoking the regular C<done> method as part of the C<await>
operation called on the toplevel future. This makes the future complete with
the given result, but only when C<get> is called.

=cut

sub done_later
{
   my $self = ref $_[0] ? shift : shift->new;
   push @deferrals, [ $self, done => @_ ];
   return $self;
}

=head2 fail_later

   $f->fail_later( $message, $category, @details )

Equivalent to invoking the regular C<fail> method as part of the C<await>
operation called on the toplevel future. This makes the future complete with
the given failure, but only when C<get> is called. As the C<failure> method
also waits for completion of the future, then it will return the failure
message given here also.

=cut

sub fail_later
{
   my $self = ref $_[0] ? shift : shift->new;
   push @deferrals, [ $self, fail => @_ ];
   return $self;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
