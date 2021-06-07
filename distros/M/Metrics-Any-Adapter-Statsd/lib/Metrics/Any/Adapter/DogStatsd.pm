#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2021 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::DogStatsd 0.03;

use v5.14;
use warnings;
use base qw( Metrics::Any::Adapter::Statsd );

use Carp;

# See also
#   https://metacpan.org/release/DataDog-DogStatsd/source/lib/DataDog/DogStatsd.pm

=head1 NAME

C<Metrics::Any::Adapter::DogStatsd> - a metrics reporting adapter for DogStatsd

=head1 SYNOPSIS

   use Metrics::Any::Adapter 'DogStatsd';

This extension of L<Metrics::Any::Adapter::Statsd> supports the additional tag
reporting syntax defined by F<DogStatsd> to report labelled metrics.

Additionally, distribution metrics are reported as native DogStatsd histograms
rather than the two-part count-and-sum implementation of plain statsd.

=cut

sub _tags
{
   my ( $labels, $labelvalues ) = @_;

   my @tags;
   foreach ( 0 .. $#$labels ) {
      push @tags, "$labels->[$_]:$labelvalues->[$_]";
   }

   return "" unless @tags;
   return "|#" . join( ",", @tags );
}

sub send
{
   my $self = shift;
   my ( $stats, $labelnames, $labelvalues ) = @_;

   foreach my $name ( keys %$stats ) {
      my $value = $stats->{$name};
      my @values = ( ref $value ) ? @$value : ( $value );
      $_ .= _tags( $labelnames, $labelvalues ) for @values;
      $stats->{$name} = \@values
   }

   $self->SUPER::send( $stats );
}

# DogStatsd has a native "histogram" format; we'll use that
sub report_distribution
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   my $meta = $self->{metrics}{$handle} or croak "No metric '$handle'";

   my $value = sprintf "%g|h", $amount;

   $self->send( { $meta->{name} => $value }, $meta->{labels}, \@labelvalues );
}

*inc_distribution_by = \&report_distribution;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
