#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2026 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::SignalFx 0.04;

use v5.14;
use warnings;
use base qw( Metrics::Any::Adapter::Statsd );

# See also
#   https://docs.signalfx.com/en/latest/integrations/agent/monitors/collectd-statsd.html

=head1 NAME

C<Metrics::Any::Adapter::SignalFx> - a metrics reporting adapter for SignalFx

=head1 SYNOPSIS

=for highlighter language=perl

   use Metrics::Any::Adapter 'SignalFx';

=head1 DESCRIPTION

This extension of L<Metrics::Any::Adapter::Statsd> supports the additional tag
reporting syntax defined by F<SignalFx> to report labelled metrics. Due to
limitations of the line-based protocol, certain characters are not allowed in
label names or values. Any C<[>, C<]>, C<,>, C<|>, C<=> or linefeeds are
replaced by C<_>.

=cut

sub _labels
{
   my ( $labelnames, $labelvalues ) = @_;

   my @labels;
   foreach ( 0 .. $#$labelnames ) {
      my $name  = $labelnames->[$_];
      my $value = $labelvalues->[$_];
      # Replace disallowed characters with '_'
      $_ =~ s/[][,|=\n]/_/g for $name, $value;

      push @labels, "$name=$value";
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
