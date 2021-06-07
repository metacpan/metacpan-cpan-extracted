#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2021 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::SignalFx 0.03;

use v5.14;
use warnings;
use base qw( Metrics::Any::Adapter::Statsd );

# See also
#   https://docs.signalfx.com/en/latest/integrations/agent/monitors/collectd-statsd.html

=head1 NAME

C<Metrics::Any::Adapter::SignalFx> - a metrics reporting adapter for SignalFx

=head1 SYNOPSIS

   use Metrics::Any::Adapter 'SignalFx';

This extension of L<Metrics::Any::Adapter::Statsd> supports the additional tag
reporting syntax defined by F<SignalFx> to report labelled metrics.

=cut

sub _labels
{
   my ( $labelnames, $labelvalues ) = @_;

   my @labels;
   foreach ( 0 .. $#$labelnames ) {
      push @labels, "$labelnames->[$_]=$labelvalues->[$_]";
   }

   return "[" . join( ",", @labels ) . "]";
}

sub send
{
   my $self = shift;
   my ( $stats, $labelnames, $labelvalues ) = @_;

   my %labelledstats;
   if( $labelnames ) {
      foreach my $name ( keys %$stats ) {
         my $value = $stats->{$name};
         my @parts = split m/\./, $name;
         $parts[-1] = _labels( $labelnames, $labelvalues ) . $parts[-1];
         $name = join ".", @parts;

         $labelledstats{$name} = $value;
      }
   }
   else {
      %labelledstats = %$stats;
   }

   $self->SUPER::send( \%labelledstats );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
