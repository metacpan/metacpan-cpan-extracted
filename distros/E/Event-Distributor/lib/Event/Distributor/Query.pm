#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2021 -- leonerd@leonerd.org.uk

package Event::Distributor::Query 0.06;

use v5.14;
use warnings;
use base qw( Event::Distributor::_Event );

use Future;

=head1 NAME

C<Event::Distributor::Query> - an event that collects a result

=head1 DESCRIPTION

This subclass of L<Event::Distributor::_Event> invokes each of its subscribers
in turn, yielding either the (first) successful and non-empty result, or a
failure if they all fail. Yields a (successful) empty result if there are no
subscribers.

=cut

sub fire
{
   my $self = shift;
   my ( $dist, @args ) = @_;

   my $await = $self->{await};
   my @f;

   foreach my $sub ( $self->subscribers ) {
      my $f = $sub->( $dist, @args )->then_with_f( sub {
         my $f = shift;
         return $f if @_;
         die "No result\n";
      });

      push @f, $f;

      last if $f->is_ready and !$f->failure;
   }

   return Future->done if !@f;

   return Future->needs_any( @f )->then( sub {
      my @results = @_;
      # TODO: conversions?
      Future->done( @results );
   })->else_with_f( sub {
      my $f = shift;
      my @other_fails = grep { $_->failure ne "No result\n" } $f->failed_futures;

      return $other_fails[0] if @other_fails;
      Future->done();
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA
