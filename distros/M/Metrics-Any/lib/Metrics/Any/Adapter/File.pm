#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::File 0.06;

use v5.14;
use warnings;

use Carp;

=head1 NAME

C<Metrics::Any::Adapter::File> - write metrics to a file

=head1 SYNOPSIS

   use Metrics::Any::Adapter 'File', path => "metrics.log";

=head1 DESCRIPTION

This L<Metrics::Any> adapter type writes observations of metric values into a
file. This may be helpful while debugging or otherwise testing code that
reports metrics.

For example, by setting the C<METRICS_ANY_ADAPTER> environment variable to
configure the adapter, a metric log will be written as a side-effect of
running a unit test:

   $ METRICS_ANY_ADAPTER=File:path=metrics.log perl -Mblib t/01test.t

The generated file can then be inspected to see what metric values were
reported while the program was running.

In particular, specifying the file F</dev/null> allows the full metrics
generation path to be tested with the code under test seeing a "real" adapter
even though the output goes nowhere.

   $ METRICS_ANY_ADAPTER=File:path=/dev/null ./Build test

Distribution and timing metrics are tracked with a running total and count of
observations.

=head1 ARGUMENTS

The following additional arguments are recognised

=head2 path

The path to the file to write to.

=cut

my %metrics;

sub new
{
   my $class = shift;
   my %args = @_;

   my $fh;
   if( $args{fh} ) {
      # fh isn't documented but useful for unit testing
      $fh = $args{fh};
   }
   elsif( $args{path} ) {
      open $fh, ">>", $args{path} or die "Cannot open $args{path} for writing - $!\n";
   }
   else {
      croak "Require a 'path' argument";
   }

   $fh->autoflush;

   return bless {
      __fh => $fh,
   }, $class;
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
   my $fh = $self->{__fh};

   my $key = $self->_key( $handle, undef, @labelvalues );
   my $current = $metrics{$key} += $amount;

   printf $fh "METRIC COUNTER %s %+g => %g\n",
      $key, $amount, $current;
}

sub make_distribution { shift->_make( distribution => @_ ) }

sub report_distribution
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;
   my $fh = $self->{__fh};

   my $count = $metrics{ $self->_key( $handle, "_count", @labelvalues ) } += 1;
   my $total = $metrics{ $self->_key( $handle, "_total", @labelvalues ) } += $amount;

   printf $fh "METRIC DISTRIBUTION %s +%g => %g/%d [avg=%g]\n",
      $self->_key( $handle, undef, @labelvalues ), $amount, $total, $count, $total/$count;
}

sub make_gauge { shift->_make( gauge => @_ ) }

sub inc_gauge_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;
   my $fh = $self->{__fh};

   my $key = $self->_key( $handle, undef, @labelvalues );
   my $current = $metrics{$key} += $amount;

   printf $fh "METRIC GAUGE %s %+g => %g\n",
      $key, $amount, $current;
}

sub set_gauge_to
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;
   my $fh = $self->{__fh};

   my $key = $self->_key( $handle, undef, @labelvalues );
   my $current = $metrics{$key} = $amount;

   printf $fh "METRIC GAUGE %s => %g\n",
      $key, $current;
}

sub make_timer { shift->_make( timer => @_ ) }

sub report_timer
{
   my $self = shift;
   my ( $handle, $duration, @labelvalues ) = @_;
   my $fh = $self->{__fh};

   my $count = $metrics{ $self->_key( $handle, "_count", @labelvalues ) } += 1;
   my $total = $metrics{ $self->_key( $handle, "_total", @labelvalues ) } += $duration;

   printf $fh "METRIC TIMER %s +%.3g => %.3g/%d [avg=%g]\n",
      $self->_key( $handle, undef, @labelvalues ), $duration, $total, $count, $total/$count;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
