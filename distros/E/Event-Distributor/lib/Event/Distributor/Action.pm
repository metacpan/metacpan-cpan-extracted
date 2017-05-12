#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package Event::Distributor::Action;

use strict;
use warnings;
use base qw( Event::Distributor::_Event );

our $VERSION = '0.04';

use Carp;

use Future;

=head1 NAME

C<Event::Distributor::Action> - an event that requires one subscriber

=head1 DESCRIPTION

This subclass of L<Event::Distributor::_Event> requires exactly one subscriber
at the time that it is invoked. It passes on the caller's arguments to the
subscriber, and the subscriber's return value back to the caller.

=cut

sub subscribe
{
   my $self = shift;
   $self->subscribers and croak "Too many subscribers";

   $self->SUPER::subscribe( @_ );
}

sub fire
{
   my $self = shift;
   my ( $dist, @args ) = @_;

   my @subs = $self->subscribers or
      return Future->fail( "No subscribers" );

   Future->call( $subs[0], $dist, @args );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
