#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Event::Distributor::Query;

use strict;
use warnings;
use base qw( Event::Distributor::_Event );

our $VERSION = '0.04';

use Future;

=head1 NAME

C<Event::Distributor::Query> - an event that collects a result

=head1 DESCRIPTION

This subclass of L<Event::Distributor::_Event> invokes each of its subscribers
in turn, yielding either the (first) successful result, or a failure if they
all fail.

=cut

sub fire
{
   my $self = shift;
   my ( $dist, @args ) = @_;

   my $await = $self->{await};
   my @f;

   foreach my $sub ( $self->subscribers ) {
      my $f = $sub->( $dist, @args );
      push @f, $f;

      last if $f->is_ready and !$f->failure;
   }

   return Future->needs_any( @f )->then( sub {
      my @results = @_;
      # TODO: conversions?
      Future->done( @results );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA
