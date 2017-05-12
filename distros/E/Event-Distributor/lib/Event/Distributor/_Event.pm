#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package Event::Distributor::_Event;

use strict;
use warnings;

our $VERSION = '0.04';

use Future;

=head1 NAME

C<Event::Distributor::_Event> - base class for L<Event::Distributor> events

=head1 DESCRIPTION

This class is the base from which the following actual classes are derived:

=over 2

=item *

L<Event::Distributor::Signal>

=item *

L<Event::Distributor::Query>

=back

Instances of this class shouldn't be directly created by end-user code, but it
is documented here in order to list the shared methods available on all the
subclasses.

=cut

sub new
{
   my $class = shift;
   return bless {
      subscribers => [],
   }, $class;
}

=head1 METHODS

=cut

=head2 subscribe

   $event->subscribe( $code )

Adds a new C<CODE> reference that subscribes to the event. This code is
expected to return a L<Future> instance.

=cut

sub subscribe
{
   my $self = shift;
   my ( $code ) = @_;

   push @{ $self->{subscribers} }, $code;
}

=head2 subscribers

   @codes = $event->subscribers

Returns a list of C<CODE> references previously subscribed.

=cut

sub subscribers
{
   my $self = shift;
   return @{ $self->{subscribers} };
}

=head1 EXPECTED METHODS

Subclasses are expected to implement the following methods:

=cut

=head2 fire

   $f = $event->fire( @args )

Invoked by L<Event::Distributor> to actually run the signal. This is expected
to invoke any or all subscribers in whatever manner it implements, passing
arguments as required, and collecting results in some way to provide as the
eventual answer of the L<Future> it returns.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA
