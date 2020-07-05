#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::Tee 0.06;

use v5.14;
use warnings;

=head1 NAME

C<Metrics::Any::Adapter::Tee> - send metrics to multiple adapters

=head1 SYNOPSIS

   use Metrics::Any::Adapter 'Tee',
      "Prometheus",
      [ "File", path => "metrics.log" ],
      "Statsd";

=head1 DESCRIPTION

This L<Metrics::Any> adapter type acts as a container for multiple other
adapters, allowing an application to report its metrics via multiple different
mechanisms at the same time.

=head1 ARGUMENTS

Each value passed in the import list should either be an adapter type string
or an array reference containing the name and additional arguments.

Adapters specified by string are split in the same way as
L<Metrics::Any::Adapter> splits the C<METRICS_ANY_ADAPTER> environment
variable; namely by parsing optional arguments after a colon, separated by
commas or equals signs. E.g.

   "File:path=metrics.log"

would be equivalent to the version given in the synopsis above.

=cut

sub new
{
   my $class = shift;

   my @adapters;
   foreach ( @_ ) {
      # Adapters are probably specified by ARRAYref
      my ( $type, @args ) = ref $_ eq "ARRAY" ? @$_ : Metrics::Any::Adapter->split_type_string( $_ );
      push @adapters, Metrics::Any::Adapter->class_for_type( $type )->new( @args );
   }

   return bless {
      adapters => \@adapters,
   }, $class;
}

# Distribute each method call across all the adapters
foreach my $method (qw(
   make_counter      inc_counter_by
   make_distribution report_distribution
   make_gauge        inc_gauge_by         set_gauge
   make_timer        report_timer
)) {
   my $code = sub {
      my $self = shift;

      my @e;
      foreach my $adapter ( @{ $self->{adapters} } ) {
         defined eval { $adapter->$method( @_ ); 1 } or
            push @e, $@;
      }
      die $e[0] if @e;
   };

   no strict 'refs';
   *$method = $code;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
