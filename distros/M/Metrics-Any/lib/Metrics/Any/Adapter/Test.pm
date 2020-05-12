#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::Test;

use strict;
use warnings;

our $VERSION = '0.04';

use Carp;

=head1 NAME

C<Metrics::Any::Adapter::Test> - a metrics reporting adapter for unit testing

=head1 SYNOPSIS

   use Test::More;
   use Metrics::Any::Adapter 'Test';

   {
      Metrics::Any::Adapter::Test->clear;

      # perform some work in the code under test

      is( Metrics::Any::Adapter::Test->metrics,
         "an_expected_metric = 1\n",
         'Metrics were reported while doing something'
      );
   }

=head1 DESCRIPTION

This L<Metrics::Any> adapter type stores reported metrics locally, allowing
access to them by the L</metrics> method. This is useful to use in a unit test
to check that the code under test reports the correct metrics.

This adapter supports timer metrics by storing the count and total duration.

For predictable output of timer metrics in unit tests, a unit test may wish to
use the L</override_timer_duration> method.

=cut

my %metrics;
my $timer_duration;

=head1 METHODS

=cut

=head2 metrics

   $result = Metrics::Any::Adapter::Test->metrics

This class method returns a string describing all of the stored metric values.
Each is reported on a line formatted as

   name = value

Each line, including the final one, is terminated by a linefeed. The metrics
are sorted alphabetically. Any multi-part metric names will be joined with
underscores (C<_>).

Metrics that have additional labels are formatted with additional label names
and label values in declared order after the name and before the C<=> symbol:

   name l1:v1 l2:v2 = value

=cut

sub metrics
{
   my $class = shift;

   my $ret = "";
   foreach my $key ( sort keys %metrics ) {
      $ret .= "$key = $metrics{$key}\n";
   }

   return $ret;
}

=head2 clear

   Metrics::Any::Adapter::Test->clear

This class method removes all of the stored values of reported metrics.

=cut

sub clear
{
   shift;

   undef %metrics;
   undef $timer_duration;
}

=head2 override_timer_duration

   Metrics::Any::Adapter::Test->override_timer_duration( $duration )

This class method sets a duration value, that any subsequent call to
C<inc_timer> will use instead of the value the caller actually passed in. This
will ensure reliably predictable output in unit tests.

Any value set here will be cleared by L</clear>.

=cut

sub override_timer_duration
{
   shift;
   ( $timer_duration ) = @_;
}

sub new
{
   return bless {}, shift;
}

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
   };
}

sub _key
{
   my $self = shift;
   my ( $handle, $suffix, @labelvalues ) = @_;

   my $meta = $self->{$handle};

   my $key = $meta->{name};
   $key .= $suffix if defined $suffix;

   if( my $labels = $meta->{labels} ) {
      $key .= " $labels->[$_]:$labelvalues[$_]" for 0 .. $#$labels;
   }

   return $key;
}

sub make_counter { shift->_make( counter => @_ ) }

sub inc_counter_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   $self->{$handle}{type} eq "counter" or
      croak "$handle is not a counter metric";

   $metrics{ $self->_key( $handle, undef, @labelvalues ) } += $amount;
}

sub make_distribution { shift->_make( distribution => @_ ) }

sub inc_distribution_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   $self->{$handle}{type} eq "distribution" or
      croak "$handle is not a distribution metric";

   # TODO: Some buckets?
   $metrics{ $self->_key( $handle, "_count", @labelvalues ) } += 1;
   $metrics{ $self->_key( $handle, "_total", @labelvalues ) } += $amount;
}

sub make_gauge { shift->_make( gauge => @_ ) }

sub inc_gauge_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   $self->{$handle}{type} eq "gauge" or
      croak "$handle is not a gauge metric";

   $metrics{ $self->_key( $handle, undef, @labelvalues ) } += $amount;
}

sub set_gauge_to
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   $self->{$handle}{type} eq "gauge" or
      croak "$handle is not a gauge metric";

   $metrics{ $self->_key( $handle, undef, @labelvalues ) } = $amount;
}

sub make_timer { shift->_make( timer => @_ ) }

sub inc_timer_by
{
   my $self = shift;
   my ( $handle, $duration, @labelvalues ) = @_;

   $self->{$handle}{type} eq "timer" or
      croak "$handle is not a timer metric";

   $duration = $timer_duration if defined $timer_duration;

   $metrics{ $self->_key( $handle, "_count", @labelvalues ) } += 1;
   $metrics{ $self->_key( $handle, "_total", @labelvalues ) } += $duration;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
