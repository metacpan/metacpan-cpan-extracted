#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Event::Distributor::Signal;

use strict;
use warnings;
use base qw( Event::Distributor::_Event );

our $VERSION = '0.04';

use Future;

=head1 NAME

C<Event::Distributor::Signal> - an event that returns no result

=head1 DESCRIPTION

This subclass of L<Event::Distributor::_Event> invokes each of its subscribers
in turn, ensuring each has a chance to be invoked regardless of the result of
the others.

Its L<Future> succeeds (with no value) if no subscriber failed. If one
subscriber failed, the C<Future> fails in the same way. If two or more
subscribers fail, the resulting C<Future> fails with a message composed by
combining all the individual messages, in the C<distributor> category, whose
failure details are a list of the failed component futures.

=cut

sub fire
{
   my $self = shift;
   my ( $dist, @args ) = @_;

   return Future->wait_all(
      map {
         my $sub = $_; local $_;  # protect against corruption of $_
         Future->call( $sub, $dist, @args );
      } $self->subscribers
   )->then( sub {
      my @failed = grep { $_->failure } @_;

      return Future->done() if !@failed;
      return $failed[0] if @failed == 1;
      return Future->fail( "Multiple subscribers failed:\n" .
         join( "", map { " | " . $_->failure } @failed ),
         distributor => @failed,
      );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA
