#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::AdapterBase::Stored 0.06;

use v5.14;
use warnings;

use Carp;

=head1 NAME

C<Metrics::Any::AdapterBase::Stored> - a base class for metrics adapters which store values

=head1 DESCRIPTION

This base class assists in creating L<Metrics::Any::Adapter> classes which
store values of reported metrics directly. These can then be retrieved later
by the containing application, or the subclass code, by using the L</walk>
method.

This base class internally stores counter and gauge metrics as single scalar
values directly. In order to provide flexibility for a variety of
use-cases, it requires assistance from the implementing class on how to store
distribution and timer metrics. The implementing class should provide these
methods, returning whatever values it wishes to implement them with. These
values are stored by the base class, and handed back as part of the L</walk>
method.

The base class stores a value for each unique set of labels and values on
every metric; the subclass does not need to handle this.

=cut

sub new
{
   my $class = shift;

   # Metrics are keys of $self, named by handle
   return bless {}, $class;
}

=head1 METHODS

=cut

sub _make
{
   my $self = shift;
   my ( $type, $handle, %args ) = @_;

   my $name = $args{name};
   $name = join "_", @$name if ref $name eq "ARRAY";

   $self->{$handle} = {
      type   => $type,
      name   => $name,
      labels => $args{labels},
      values => {}, # values per labelset
   };
}

sub _metric
{
   my $self = shift;
   my ( $type, $handle ) = @_;

   my $metric = $self->{$handle};
   $metric->{type} eq $type or
      croak "$handle is not a $type metric";

   return $metric;
}

sub _labelset
{
   my $self = shift;
   my ( $handle, @labelvalues ) = @_;

   my $metric = $self->{$handle};

   my $labels = $metric->{labels} or return "";

   return join "\0", map { "$labels->[$_]:$labelvalues[$_]" } 0 .. $#$labels;
}

=head2 walk

   $stored->walk( $code )

      $code->( $type, $name, $labels, $value )

Given a CODE reference, this method invokes it once per labelset of every
stored metric.

For each labelset, C<$type> will give the metric type (as a string, either
C<counter>, C<distribution>, C<gauge> or C<timer>), C<$name> gives the name
it was registered with, C<$labels> will be a reference to an even-sized array
containing label names and values.

For counter and gauge metrics, C<$value> will be a numerical scalar giving the
current value. For distribution and timer metrics, C<$value> will be whatever
the implementing class's corresponding C<store_distribution> or C<store_timer>
method returns for them.

=cut

sub walk
{
   my $self = shift;
   my ( $code ) = @_;

   foreach my $handle ( sort keys %$self ) {
      my $metric = $self->{$handle};
      my $values = $metric->{values};

      foreach my $labelset ( sort keys %$values ) {
         my @labels = map { split m/:/, $_, 2 } split m/\0/, $labelset;

         $code->( $metric->{type}, $metric->{name}, \@labels, $values->{$labelset} );
      }
   }
}

=head2 clear_values

   $stored->clear_values

Clears all of the metric storage. Every labelset of every metric is deleted.
The metric definitions themselves remain.

=cut

sub clear_values
{
   my $self = shift;

   $_->{values} = {} for values %$self;
}

sub make_counter { shift->_make( counter => @_ ) }

sub inc_counter_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   my $metric = $self->_metric( counter => $handle );

   $metric->{values}{ $self->_labelset( $handle, @labelvalues ) } += $amount;
}

sub make_distribution { shift->_make( distribution => @_ ) }

sub report_distribution
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   my $metric = $self->_metric( distribution => $handle );

   my $values = $metric->{values};
   my $key = $self->_labelset( $handle, @labelvalues );

   $values->{$key} = $self->store_distribution( $values->{$key}, $amount );
}

sub make_gauge { shift->_make( gauge => @_ ) }

sub inc_gauge_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   my $metric = $self->_metric( gauge => $handle );

   $metric->{values}{ $self->_labelset( $handle, @labelvalues ) } += $amount;
}

sub set_gauge_to
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   my $metric = $self->_metric( gauge => $handle );

   $metric->{values}{ $self->_labelset( $handle, @labelvalues ) } = $amount;
}

sub make_timer { shift->_make( timer => @_ ) }

sub report_timer
{
   my $self = shift;
   my ( $handle, $duration, @labelvalues ) = @_;

   my $metric = $self->_metric( timer => $handle );

   my $values = $metric->{values};
   my $key = $self->_labelset( $handle, @labelvalues );

   $values->{$key} = $self->store_timer( $values->{$key}, $duration );
}

=head1 REQUIRED METHODS

=head2 store_distribution

=head2 store_timer

   $storage = $stored->store_distribution( $storage, $amount )

   $storage = $stored->store_timer( $storage, $duration )

The implementing class must provide these two methods to assist in the
management of storage for distribution and timer metrics.

When a new observation for the metric is required, the method will be invoked,
passing in the currently-stored perl value for the given metric and label
values, and the new observation. Whatever the method returns is stored by the
base class, to be passed in next time or used by the L</walk> method.

The base class stores this value directly and does not otherwise interact with
it; letting the implementing class decide what is best. For example, a simple
implementation may just store every observation individually by pushing them
into an array; so the C<$storage> would be an ARRAY reference:

   sub store_distribution
   {
      my $self = shift;
      my ( $storage, $amount ) = @_;

      push @$storage, $amount;

      return $storage;
   }

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
