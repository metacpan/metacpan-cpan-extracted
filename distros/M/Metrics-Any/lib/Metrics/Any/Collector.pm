#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Collector;

use strict;
use warnings;

our $VERSION = '0.03';

use Metrics::Any::Adapter;

=head1 NAME

C<Metrics::Any::Collector> - module-side of the monitoring metrics reporting API

=head1 SYNOPSIS

   use Metrics::Any '$metrics';

   $metrics->make_counter( thing =>
      name => [qw( things done )],
   );

   sub do_thing {
      $metrics->inc_counter( 'thing' );
   }

=head1 DESCRIPTION

Instances of this class provide an API for individual modules to declare
metadata about metrics they will report, and to report individual values or
observations on those metrics. An instance should be obtained for a reporting
module by the C<use Metrics::Any> statement.

The collector acts primarily as a proxy for the application's configured
L<Metrics::Any::Adapter> instance. The proxy will lazily create an adapter
when required to first actually report a metric value, but until then any
metadata stored by any of the C<make_*> methods will not create one. This lazy
deferral allows a certain amount of flexibility with module load order and
application startup. By carefully writing module code to not report any values
of metrics until the main activity has actually begin, it should be possible
to allow programs to configure the metric reporting in a flexible manner
during program startup.

=cut

# Not public API; used by Metrics::Any::import_into
sub new
{
   my $class = shift;
   my ( $pkg ) = @_;

   return bless {
      pkg => $pkg,
      adapter => undef,
      deferred => [],
   }, $class;
}

sub adapter
{
   my $self = shift;
   return $self->{adapter} if $self->{adapter};

   my $adapter = $self->{adapter} = Metrics::Any::Adapter->adapter;
   foreach my $call ( @{ $self->{deferred} } ) {
      my ( $method, @args ) = @$call;
      $self->$method( @args );
   }
   undef $self->{deferred};
   return $adapter;
}

=head1 BOOLEAN OVERRIDE

Instances of this class override boolean truth testing. They are usually true,
except in the case that an adapter has already been created and it is the Null
type. This allows modules to efficiently test whether to report metrics at all
by using code such as

   if( $metrics ) {
      $metrics->inc_counter( name => some_expensive_function() );
   }

While the Null adapter will simply ignore any of the methods invoked on it,
without this conditional test the caller would otherwise still have to
calculate the value that won't be used. This structure allows the calculation
to be avoided if metrics are not in use.

=cut

use overload
   'bool' => sub {
      !$_[0]->{adapter} or ref $_[0]->{adapter} ne "Metrics::Any::Adapter::Null"
   },
   fallback => 1;

=head1 METRIC TYPES

Each type of metric is created by one of the C<make_*> methods. They all take
the following common arguments:

=over 4

=item name => ARRAY[ STRING ] | STRING

An array of string parts, or a plain string name to use for reporting this
metric to its upstream service.

Modules should preferrably use an array of string parts to specify their
metric names, as different adapter types may have different ways to represent
this hierarchially. Base-level parts of the name should come first, followed
by more specific parts. It is common for related metrics to be grouped by name
having identical prefixes but differing only in the final part.

=item description => STRING

Optional human-readable description. May be used for debugging or other
purposes.

=item labels => ARRAY[ STRING ]

Optional reference to an array of string names to use as label names.

A labelled metric will expect to receive as many additional values to a call
to its reporting method as there are label names. Each additional value will
be associated with the corresponding label.

Note that not all metric reporting adapters may be able to represent all of
the labels. Each should document what its behaviour will be.

=back

=cut

=head2 Counter

The L</make_counter> method creates a new metric which counts occurances of
some event within the application. Its value begins at zero, and can be
incremented by L</inc_counter> whenever the event occurs.

Some counters may simple count occurances of events, while others may count
in other units, for example counts of bytes. Adapters may make use of the
C<units> parameter of the distribution to perform some kind of
adapter-specific behaviour. The following units are suggested:

=head3 bytes

Observations give sizes in bytes (perhaps memory buffer or network message
sizes), and should be integers.

=cut

=head2 make_counter

   $collector->make_counter( $handle, %args )

Requests the creation of a new counter metric. The C<$handle> name should be
unique within the collector instance, though does not need to be unique across
the entire program, as it will be namespaced by the collector instance.

The following extra arguments may be passed:

=over 4

=item units => STRING

A hint to the adapter about what kind of measurements are being observed, so
it might take specific behaviour.

=back

=cut

sub make_counter
{
   my $self = shift;
   my ( $handle, %args ) = @_;

   if( !$self->{adapter} ) {
      push @{ $self->{deferred} }, [ make_counter => $handle, %args ];
      return;
   }

   $self->adapter->make_counter( "$self->{pkg}/$handle", %args );
}

=head2 inc_counter

   $collector->inc_counter( $handle, @labelvalues )

Reports that the counter metric value be incremented by one. The C<$handle>
name must match one earlier created by L</make_counter>.

=cut

sub inc_counter
{
   my $self = shift;
   my ( $handle, @labelvalues ) = @_;

   $self->adapter->inc_counter_by( "$self->{pkg}/$handle", 1, @labelvalues );
}

=head2 inc_counter_by

   $collector->inc_counter_by( $handle, $amount, @labelvalues )

Reports that a counter metric value be incremented by some specified value.

=cut

sub inc_counter_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   $self->adapter->inc_counter_by( "$self->{pkg}/$handle", $amount, @labelvalues );
}

=head2 Distribution

The L</make_distribution> method creates a new metric which counts individual
observations of some numerical quantity (which may or may not be integral).
New observations can be added by the L</inc_distribution_by> method.

Some adapter types may only store an aggregated total; others may store some
sort of statistical breakdown, either total + count, or a bucketed histogram.
The specific adapter documentation should explain how it handles
distributions.

Adapters may make use of the C<units> parameter of the distribution to perform
some kind of adapter-specific behaviour. The following units are suggested:

=head3 bytes

Observations give sizes in bytes (perhaps memory buffer or network message
sizes), and should be integers.

=head3 seconds

Observations give durations in seconds.

=cut

=head2 make_distribution

   $collector->make_distribution( $handle, %args )

Requests the creation of a new distribution metric.

The following extra arguments may be passed:

=over 4

=item units => STRING

A hint to the adapter about what kind of measurements are being observed, so
it might take specific behaviour. If unspecified, a default of C<bytes> will
apply.

=back

=cut

sub make_distribution
{
   my $self = shift;
   my ( $handle, %args ) = @_;

   $args{units} //= "bytes";

   if( !$self->{adapter} ) {
      push @{ $self->{deferred} }, [ make_distribution => $handle, %args ];
      return;
   }

   $self->adapter->make_distribution( "$self->{pkg}/$handle", %args );
}

=head2 inc_distribution_by

   $collector->inc_distribution_by( $handle, $amount, @labelvalues )

Reports a new observation for the distribution metric. The C<$handle> name
must match one earlier created by L</make_distribution>. The C<$amount> may
be interpreted by the adapter depending on the defined C<units> type for the
distribution.

=cut

sub inc_distribution_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   $self->adapter->inc_distribution_by( "$self->{pkg}/$handle", $amount, @labelvalues );
}

=head2 Gauge

The L</make_gauge> method creates a new metric which reports on the
instantaneous value of some measurable quantity. Unlike the other metric types
this does not have to only increment forwards when certain events occur, but
can measure a quantity that may both increase and decrease over time; such as
the number some kind of object in memory, or the size of some data structure.

As an alternative to incrementing or decrementing the value when particular
events occur, the absolute value of the gauge can also be set directly.

=cut

=head2 make_gauge

   $collector->make_gauge( $handle, %args )

Requests the creation of a new gauge metric.

=cut

sub make_gauge
{
   my $self = shift;
   my ( $handle, %args ) = @_;

   if( !$self->{adapter} ) {
      push @{ $self->{deferred} }, [ make_gauge => $handle, %args ];
      return;
   }

   $self->adapter->make_gauge( "$self->{pkg}/$handle", %args );
}

=head2 inc_gauge

   $collector->inc_gauge( $handle, @labelvalues )

=head2 dec_gauge

   $collector->dec_gauge( $handle, @labelvalues )

=head2 inc_gauge_by

   $collector->inc_gauge_by( $handle, $amount, @labelvalues )

=head2 dec_gauge_by

   $collector->dec_gauge_by( $handle, $amount, @labelvalues )

Reports that the observed value of the gauge has increased or decreased by the
given amount (or 1).

=cut

sub inc_gauge
{
   my $self = shift;
   my ( $handle, @labelvalues ) = @_;

   $self->adapter->inc_gauge_by( "$self->{pkg}/$handle", 1, @labelvalues );
}

sub dec_gauge
{
   my $self = shift;
   my ( $handle, @labelvalues ) = @_;

   $self->adapter->inc_gauge_by( "$self->{pkg}/$handle", -1, @labelvalues );
}

sub inc_gauge_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   $self->adapter->inc_gauge_by( "$self->{pkg}/$handle", $amount, @labelvalues );
}

sub dec_gauge_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   $self->adapter->inc_gauge_by( "$self->{pkg}/$handle", -$amount, @labelvalues );
}

=head2 set_gauge_to

   $collector->set_gauge_to( $handle, $amount, @labelvalues )

Reports that the observed value of the gauge is now the given amount.

The C<$handle> name must match one earlier created by L</make_gauge>.

=cut

sub set_gauge_to
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   $self->adapter->set_gauge_to( "$self->{pkg}/$handle", $amount, @labelvalues );
}

=head2 Timer

The L</make_timer> method creates a new metric which measures durations of
time consumed by the application. New observations of durations can be added
by the L</inc_timer> method.

Timer metrics may be handled by the adapter similarly to distribution metrics.
Moreover, adapters may choose to implement timers as distributions with units
of C<seconds>.

=cut

=head2 make_timer

   $collector->make_timer( $handle, %args )

Requests the creation of a new timer metric.

=cut

sub make_timer
{
   my $self = shift;
   my ( $handle, %args ) = @_;

   if( !$self->{adapter} ) {
      push @{ $self->{deferred} }, [ make_timer => $handle, %args ];
      return;
   }

   $self->adapter->make_timer( "$self->{pkg}/$handle", %args );
}

=head2 inc_timer_by

   $collector->inc_timer_by( $handle, $duration, @labelvalues )

Reports a new duration for the timer metric. The C<$handle> name must match
one earlier created by L</make_timer>. The C<$duration> gives a time measured
in seconds, and may be fractional.

=cut

sub inc_timer_by
{
   my $self = shift;
   my ( $handle, $duration, @labelvalues ) = @_;

   $self->adapter->inc_timer_by( "$self->{pkg}/$handle", $duration, @labelvalues );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
