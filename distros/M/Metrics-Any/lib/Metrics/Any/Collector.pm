#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Collector 0.06;

use v5.14;
use warnings;

use Carp;

use Metrics::Any::Adapter;

use List::Util 1.29 qw( pairkeys );

=head1 NAME

C<Metrics::Any::Collector> - module-side of the monitoring metrics reporting API

=head1 SYNOPSIS

   use Metrics::Any '$metrics',
      strict => 0,
      name_prefix => [ 'my_module_name' ];

   sub do_thing {
      $metrics->inc_counter( 'things_done' );
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
   my ( $package, %args ) = @_;

   return bless {
      package => $package,
      adapter => undef,
      deferred => [],
      name_prefix => $args{name_prefix},
      metrics => {},
      strict => $args{strict} // 1,
   }, $class;
}

sub adapter
{
   my $self = shift;
   return $self->{adapter} if $self->{adapter};

   my $adapter = $self->{adapter} = Metrics::Any::Adapter->adapter;
   foreach my $call ( @{ $self->{deferred} } ) {
      my ( $method, @args ) = @$call;
      $adapter->$method( @args );
   }
   undef $self->{deferred};
   return $adapter;
}

sub _adapter_call
{
   my $self = shift;
   my ( $method, @args ) = @_;

   if( $self->{adapter} ) {
      $self->{adapter}->$method( @args );
   }
   else {
      push @{ $self->{deferred} }, [ $method, @args ];
   }
}

sub _metricname
{
   my $self = shift;
   my ( $suffix ) = @_;

   return $suffix unless defined $self->{name_prefix};
   return [ @{ $self->{name_prefix} }, @$suffix ];
}

sub _labelvalues
{
   my $self = shift;
   my ( $type, $handle, @args ) = @_;

   my $meta = $self->{$handle};
   if( $meta ) {
      $meta->[0] eq $type or croak "Metric '$handle' is not a $type";
   }
   elsif( !$self->{strict} ) {
      my @labelnames;
      if( !@args ) {
         # no labels
      }
      elsif( ref $args[0] eq "ARRAY" ) {
         @labelnames = pairkeys @{ $args[0] };
      }
      elsif( ref $args[0] eq "HASH" ) {
         carp "Lazily creating a labelled metric with multiple labels using a HASH reference yields unreliable label order"
            if keys %{ $args[0] } > 1;
         @labelnames = keys %{ $args[0] };
      }
      else {
         croak "Cannot lazily create a labelled metric from label values specified in a flat list";
      }

      my $make_method = "make_$type";
      $self->$make_method( $handle, labels => \@labelnames );

      $meta = $self->{$handle};
   }
   else {
      croak "No such metric '$handle'";
   }

   my ( undef, @labelnames ) = @$meta;

   if( !@args ) {
      return;
   }
   elsif( ref $args[0] ) {
      warn "Received additional arguments to metrics reporting function\n" if @args > 1;
      my ( $arg ) = @args;
      my %v = ( ref $arg eq "ARRAY" ) ? @$arg : %$arg;

      my @labelvalues;
      ( defined $v{$_} or croak "Missing value for label '$_'" ) and push @labelvalues, delete $v{$_}
         for @labelnames;

      # Warn but don't complain about extra values
      carp "Found extra label value for '$_'" for keys %v;

      return @labelvalues;
   }
   else {
      return @args;
   }
}

=head1 ARGUMENTS

=head2 name_prefix

I<Since version 0.05.>

Optional prefix to prepend to any name provided to the C<make_*> functions.

If set, this value and the registered names must be given as array references,
not simple strings.

   use Metrics::Any '$metrics', name_prefix => [qw( my_program_name )];

   $metrics->make_counter( events =>
      name => [ "events" ],
   );

   # Will create a counter named ["my_program_name", "events"] formed by the
   # adapter.

=head2 strict

I<Since version 0.05.>

Optional boolean which controls whether metrics must be registered by a
C<make_> method before they can be used (when true), or whether to attempt
lazily registering them when first encountered by a reporting method (when
false).

When strict mode is off and a reporting method (e.g. C<inc_counter>) is
invoked on an unrecognised handle, it will be lazily registered. If the metric
is reported with values, an attempt is made to determine what the list of
label names is; which will depend on the form the label values are given in.
Labels passed by array reference, or by hash reference for a single label will
work fine. If a hash reference is passed with multiple keys, a warning is
printed that the order may not be reliable. Finally, for (discouraged) flat
lists of values directly it is not possible to recover label name information
so an exception is thrown.

For this reason, when operating with strict mode off, it is recommended always
to use the array reference form of supplying labels, to ensure they are
registered correctly.

In the current version this parameter defaults true, and thus all metrics must
be registered in advance. This may be changed in a future version for
convenience in smaller modules, so paranoid authors should set it explicitly:

   use Metrics::Any::Adapter '$metrics', strict => 1;

If strict mode is switched off, it is recommended to set a name prefix to
ensure that lazily-registered metrics will at least have a useful name.

=cut

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
   # stringify as itself otherwise bool takes over and it just prints as 1,
   # leading to much developer confusion
   '""' => sub { $_[0] },
   fallback => 1;

=head1 METHODS

   $package = $metrics->package

Returns the package name that created the collector; the package in which the

   use Metrics::Any '$metrics';

statement was invoked.

=cut

sub package
{
   my $self = shift;
   return $self->{package};
}

=head1 METRIC TYPES

Each type of metric is created by one of the C<make_*> methods. They all take
the following common arguments:

=over 4

=item name => ARRAY[ STRING ] | STRING

Optional. An array of string parts, or a plain string name to use for
reporting this metric to its upstream service.

Modules should preferrably use an array of string parts to specify their
metric names, as different adapter types may have different ways to represent
this hierarchially. Base-level parts of the name should come first, followed
by more specific parts. It is common for related metrics to be grouped by name
having identical prefixes but differing only in the final part.

The name is optional; if unspecified then the handle will be used to form the
name, combined with a C<name_prefix> argument if one was set for the package.

=item description => STRING

Optional human-readable description. May be used for debugging or other
purposes.

=item labels => ARRAY[ STRING ]

Optional reference to an array of string names to use as label names.

A labelled metric will expect to receive additional information in its
reporting method to give values for these labels. This information should be
in either an even-length array reference of name/value pairs, or a hash
reference. E.g.

   $metrics->inc_counter( handle => [ labelname => $labelvalue ] );
   $metrics->inc_counter( handle => { labelname => $labelvalue } );

A legacy form where a plain list of values is passed, each corresponding to a
named label in the same order, is currently accepted but discouraged in favour
of the above forms.

   $metrics->inc_counter( handle => $labelvalue );

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

   $args{name} = $self->_metricname( $args{name} // [ $handle ] );

   $self->{$handle} and croak "Already have a metric '$handle'";
   $self->{$handle} = [ counter => @{ $args{labels} // [] } ];

   $self->_adapter_call( make_counter => "$self->{package}/$handle",
      collector => $self,
      %args
   );
}

=head2 inc_counter

   $collector->inc_counter( $handle, $labels )

Reports that the counter metric value be incremented by one. The C<$handle>
name must match one earlier created by L</make_counter>.

=cut

sub inc_counter
{
   my $self = shift;
   my ( $handle, @args ) = @_;

   my @labelvalues = $self->_labelvalues( counter => $handle, @args );

   $self->adapter->inc_counter_by( "$self->{package}/$handle", 1, @labelvalues );
}

=head2 inc_counter_by

   $collector->inc_counter_by( $handle, $amount, $labels )

Reports that a counter metric value be incremented by some specified value.

=cut

sub inc_counter_by
{
   my $self = shift;
   my ( $handle, $amount, @args ) = @_;

   my @labelvalues = $self->_labelvalues( counter => $handle, @args );

   $self->adapter->inc_counter_by( "$self->{package}/$handle", $amount, @labelvalues );
}

=head2 Distribution

The L</make_distribution> method creates a new metric which counts individual
observations of some numerical quantity (which may or may not be integral).
New observations can be added by the L</report_distribution> method.

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

   $args{name} = $self->_metricname( $args{name} // [ $handle ] );

   $args{units} //= "bytes";

   $self->{$handle} and croak "Already have a metric '$handle'";
   $self->{$handle} = [ distribution => @{ $args{labels} // [] } ];

   $self->_adapter_call( make_distribution => "$self->{package}/$handle",
      collector => $self,
      %args
   );
}

=head2 report_distribution

   $collector->report_distribution( $handle, $amount, $labels )

I<Since version 0.05.>

Reports a new observation for the distribution metric. The C<$handle> name
must match one earlier created by L</make_distribution>. The C<$amount> may
be interpreted by the adapter depending on the defined C<units> type for the
distribution.

This method used to be called C<inc_distribution_by> and is currently still
available as an alias.

=cut

sub report_distribution
{
   my $self = shift;
   my ( $handle, $amount, @args ) = @_;

   my @labelvalues = $self->_labelvalues( distribution => $handle, @args );

   my $adapter = $self->adapter;

   # Support new and legacy name
   my $method = $adapter->can( "report_distribution" ) // "inc_distribution_by";
   $adapter->$method( "$self->{package}/$handle", $amount, @labelvalues );
}

*inc_distribution_by = \&report_distribution;

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

   $args{name} = $self->_metricname( $args{name} // [ $handle ] );

   $self->{$handle} and croak "Already have a metric '$handle'";
   $self->{$handle} = [ gauge => @{ $args{labels} // [] } ];

   $self->_adapter_call( make_gauge => "$self->{package}/$handle",
      collector => $self,
      %args
   );
}

=head2 inc_gauge

   $collector->inc_gauge( $handle, $labels )

=head2 dec_gauge

   $collector->dec_gauge( $handle, $labels )

=head2 inc_gauge_by

   $collector->inc_gauge_by( $handle, $amount, $labels )

=head2 dec_gauge_by

   $collector->dec_gauge_by( $handle, $amount, $labels )

Reports that the observed value of the gauge has increased or decreased by the
given amount (or 1).

=cut

sub inc_gauge
{
   my $self = shift;
   my ( $handle, @args ) = @_;

   my @labelvalues = $self->_labelvalues( gauge => $handle, @args );

   $self->adapter->inc_gauge_by( "$self->{package}/$handle", 1, @labelvalues );
}

sub dec_gauge
{
   my $self = shift;
   my ( $handle, @args ) = @_;

   my @labelvalues = $self->_labelvalues( gauge => $handle, @args );

   $self->adapter->inc_gauge_by( "$self->{package}/$handle", -1, @labelvalues );
}

sub inc_gauge_by
{
   my $self = shift;
   my ( $handle, $amount, @args ) = @_;

   my @labelvalues = $self->_labelvalues( gauge => $handle, @args );

   $self->adapter->inc_gauge_by( "$self->{package}/$handle", $amount, @labelvalues );
}

sub dec_gauge_by
{
   my $self = shift;
   my ( $handle, $amount, @args ) = @_;

   my @labelvalues = $self->_labelvalues( gauge => $handle, @args );

   $self->adapter->inc_gauge_by( "$self->{package}/$handle", -$amount, @labelvalues );
}

=head2 set_gauge_to

   $collector->set_gauge_to( $handle, $amount, $labels )

Reports that the observed value of the gauge is now the given amount.

The C<$handle> name must match one earlier created by L</make_gauge>.

=cut

sub set_gauge_to
{
   my $self = shift;
   my ( $handle, $amount, @args ) = @_;

   my @labelvalues = $self->_labelvalues( gauge => $handle, @args );

   $self->adapter->set_gauge_to( "$self->{package}/$handle", $amount, @labelvalues );
}

=head2 Timer

The L</make_timer> method creates a new metric which measures durations of
time consumed by the application. New observations of durations can be added
by the L</report_timer> method.

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

   $args{name} = $self->_metricname( $args{name} // [ $handle ] );

   $self->{$handle} and croak "Already have a metric '$handle'";
   $self->{$handle} = [ timer => @{ $args{labels} // [] } ];

   $self->_adapter_call( make_timer => "$self->{package}/$handle",
      collector => $self,
      %args
   );
}

=head2 report_timer

   $collector->report_timer( $handle, $duration, $labels )

I<Since version 0.05.>

Reports a new duration for the timer metric. The C<$handle> name must match
one earlier created by L</make_timer>. The C<$duration> gives a time measured
in seconds, and may be fractional.

This method used to called C<inc_timer_by> and is currently still available as
an alias.

=cut

sub report_timer
{
   my $self = shift;
   my ( $handle, $duration, @args ) = @_;

   my @labelvalues = $self->_labelvalues( timer => $handle, @args );

   my $adapter = $self->adapter;

   # Support new and legacy name
   my $method = $adapter->can( "report_timer" ) // "inc_timer_by";
   $adapter->$method( "$self->{package}/$handle", $duration, @labelvalues );
}

*inc_timer_by = \&report_timer;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
