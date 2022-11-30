#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2022 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::Prometheus 0.06;

use v5.14;
use warnings;

use Carp;

use Net::Prometheus::Registry;

use Net::Prometheus::Counter;
use Net::Prometheus::Gauge;
use Net::Prometheus::Histogram 0.10;

=head1 NAME

C<Metrics::Any::Adapter::Prometheus> - a metrics reporting adapter for Prometheus

=head1 SYNOPSIS

   use Metrics::Any::Adapter 'Prometheus';

=head1 DESCRIPTION

This L<Metrics::Any> adapter type reports metrics to Prometheus by using
L<Net::Prometheus>. Each metric added to the adapter will be registered with
the global L<Net::Prometheus::Registry> instance.

It becomes the calling program's responsibility to arrange for these to be
HTTP accessible by using the C<Net::Prometheus> API.

Distribution metrics are exported as Histograms by default. They may
alternatively be exported as Summaries in order to generate smaller amounts
of export data, by setting the C<use_histograms> import argument to false:

   use Metrics::Any::Adapter 'Prometheus', use_histograms => 0;

Timer metrics are implemented as distribution metrics with the units set to
C<seconds>.

This adapter type supports batch mdoe reporting. Callbacks are invoked at the
beginning of the C<Net::Prometheus> C<render> method.

=cut

package Metrics::Any::Adapter::Prometheus::_BatchCollector
{
   sub new
   {
      my $class = shift;

      return bless [], $class;
   }

   sub collect
   {
      my $self = shift;

      foreach my $cb ( @$self ) { $cb->(); }

      return ();
   }

   sub add_callback
   {
      my $self = shift;
      my ( $cb ) = @_;

      push @$self, $cb;
   }
}

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   my $self = bless {
      metrics => {},
      batch_collector => Metrics::Any::Adapter::Prometheus::_BatchCollector->new,
      use_histograms => $args{use_histograms} // 1,
   }, $class;

   # Need to register this one early before metrics are created, so it runs at
   # the right time
   Net::Prometheus::Registry->register( $self->{batch_collector} );

   return $self;
}

=head1 METHODS

=cut

use constant HAVE_BATCH_MODE => 1;

sub add_batch_mode_callback
{
   my $self = shift;
   my ( $cb ) = @_;

   $self->{batch_collector}->add_callback( $cb );
}

sub mangle_name
{
   my $self = shift;
   my ( $name ) = @_;

   $name = join "_", @$name if ref $name eq "ARRAY";

   # TODO: Consider lowercase, squashing unallowed chars to _,...

   return $name;
}

sub make_counter
{
   my $self = shift;
   my ( $handle, %args ) = @_;

   my $name = $self->mangle_name( delete $args{name} // $handle );
   my $help = delete $args{description} // "Metrics::Any counter $handle";

   if( my $units = delete $args{units} ) {
      # Append _bytes et.al. if required
      $name .= "_$units" if length $units and $name !~ m/_\Q$units\E$/;
   }
   else {
      # Prometheus policy says unitless counters take _total suffix
      $name .= "_total";
   }

   $self->{metrics}{$handle} = Net::Prometheus::Registry->register(
      Net::Prometheus::Counter->new(
         name => $name,
         help => $help,
         %args,
      )
   );
}

sub inc_counter_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   ( $self->{metrics}{$handle} or croak "No such counter named '$handle'" )
      ->inc( @labelvalues, $amount );
}

=head2 make_distribution

   $adapter->make_distribution( $name, %args )

In addition to the standard arguments, the following are recognised:

=over 4

=item buckets => ARRAY[ NUM ]

If present, overrides the default Histogram bucket sizes.

=item bucket_min => NUM

=item bucket_max => NUM

=item buckets_per_decade => ARRAY[ NUM ]

I<Since version 0.04.>

A more flexible alternative to specifying literal bucket sizes. The values
given in C<buckets_per_decade> are repeated, multiplied by various powers of
10 to generate values between C<bucket_min> (or a default of 0.001 if not
supplied) and C<bucket_max> (or a default of 1000 if not supplied).

For more information, see L<Net::Prometheus::Histogram>.

=back

=cut

my %BUCKETS_FOR_UNITS = (
   bytes   => { bucket_min => 100, bucket_max => 1E8 },
   seconds => undef, # Prometheus defaults are fine
);

sub make_distribution
{
   my $self = shift;
   my ( $handle, %args ) = @_;

   my $name = $self->mangle_name( delete $args{name} // $handle );
   my $units = delete $args{units};
   my $help  = delete $args{description} // "Metrics::Any $units distribution $handle";

   # Append _bytes et.al. if required
   $name .= "_$units" if length $units and $name !~ m/_\Q$units\E$/;

   unless( $args{buckets} ) {
      %args = ( %{ $BUCKETS_FOR_UNITS{$units} }, %args ) if $BUCKETS_FOR_UNITS{$units};
   }

   my $metric_class = $self->{use_histograms} ? "Net::Prometheus::Histogram" :
                                                "Net::Prometheus::Summary";

   $self->{metrics}{$handle} = Net::Prometheus::Registry->register(
      $metric_class->new(
         name => $name,
         help => $help,
         %args,
      )
   );
}

sub report_distribution
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   # TODO: Sanity-check that @labelvalues is as long as the label count

   ( $self->{metrics}{$handle} or croak "No such distribution named '$handle'" )
      ->observe( @labelvalues, $amount );
}

*inc_distribution_by = \&report_distribution;

sub make_gauge
{
   my $self = shift;
   my ( $handle, %args ) = @_;

   my $name = $self->mangle_name( delete $args{name} // $handle );
   my $help = delete $args{description} // "Metrics::Any gauge $handle";

   $self->{metrics}{$handle} = Net::Prometheus::Registry->register(
      Net::Prometheus::Gauge->new(
         name => $name,
         help => $help,
         %args,
      )
   );
}

sub set_gauge_to
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   ( $self->{metrics}{$handle} or croak "No such gauge named '$handle'" )
      ->set( @labelvalues, $amount );
}

sub inc_gauge_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   ( $self->{metrics}{$handle} or croak "No such gauge named '$handle'" )
      ->inc( @labelvalues, $amount );
}

sub make_timer
{
   my $self = shift;
   my ( $handle, %args ) = @_;

   $args{description} //= "Metrics::Any timer $handle";

   return $self->make_distribution( $handle,
      %args,
      units => "seconds",
   );
}

*report_timer = \&report_distribution;
*inc_timer_by = \&report_distribution;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
