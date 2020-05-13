#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter::Statsd;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;

# We don't use Net::Statsd because it
#   a) is hard to override sending for custom formats e.g. SignalFx or DogStatsd
#   b) sends differently-named stats in different packets, losing atomicity of
#      distribution updates
use IO::Socket::INET;

# TODO: Keep the same config for now
$Net::Statsd::HOST //= "127.0.0.1";
$Net::Statsd::PORT //= 8125;

=head1 NAME

C<Metrics::Any::Adapter::Statsd> - a metrics reporting adapter for statsd

=head1 SYNOPSIS

   use Metrics::Any::Adapter 'Statsd';

=head1 DESCRIPTION

This L<Metrics::Any> adapter type reports metrics to statsd via the local UDP
socket. Each metric value reported will result in a new UDP packet being sent.

The default location of the statsd server is set by two package variables,
defaulting to

   $Net::Statsd::HOST = "127.0.0.1";
   $Net::Statsd::PORT = 8125

The configuration can be changed by setting new values or by passing arguments
to the import line:

   use Metrics::Any::Adapter 'Statsd', port => 8200;

=head1 METRIC HANDLING

Unlabelled counter, gauge and timing metrics are handled natively as you would
expect for statsd; with multipart names being joined by periods (C<.>).

Distribution metrics are emitted as two sub-named metrics by appending
C<count> and C<sum>. The C<count> metric in incremented by one for each
observation and the C<sum> by the observed amount.

Labels are not handled by this adapter and are thrown away. This will result
in a single value being reported that accumulates the sum total across all of
the label values. In the case of labelled gauges using the C<set_gauge_to>
method this will not be a useful value.

For better handling of labelled metrics for certain services which have
extended the basic statsd format to handle them, see:

=over 2

=item *

L<Metrics::Any::Adapter::DogStatsd> - a metrics reporting adapter for DogStatsd

=item *

L<Metrics::Any::Adapter::SignalFx> - a metrics reporting adapter for SignalFx

=back

=head1 ARGUMENTS

The following additional arguments are recognised

=head2 host

=head2 port

Provides specific values for the statsd server location.

=cut

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   return bless {
      host => $args{host},
      port => $args{port},
      metrics => {},
      gauge_initialised => {},
   }, $class;
}

sub mangle_name
{
   my $self = shift;
   my ( $name ) = @_;

   return join ".", @$name if ref $name eq "ARRAY";

   # Convert _-separated components into .
   $name =~ s/_/./g;
   return $name;
}

sub socket
{
   my $self = shift;

   return $self->{socket} //= IO::Socket::INET->new(
      Proto    => "udp",
      PeerHost => $self->{host} // $Net::Statsd::HOST,
      PeerPort => $self->{port} // $Net::Statsd::PORT,
   );
}

sub send
{
   my $self = shift;
   my ( $stats, $labelnames, $labelvalues ) = @_;

   $self->socket->send(
      join "\n", map {
         my $name = $_;
         my $value = $stats->{$name};
         map { sprintf "%s:%s", $name, $_ } ref $value eq "ARRAY" ? @$value : $value
      } sort keys %$stats 
   );
}

sub _make
{
   my $self = shift;
   my ( $handle, %args ) = @_;

   my $name = $self->mangle_name( delete $args{name} // $handle );

   $self->{metrics}{$handle} = {
      name   => $name,
      labels => $args{labels},
   };
}

*make_counter = \&_make;

sub inc_counter_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   my $meta = $self->{metrics}{$handle} or croak "No metric '$handle'";

   my $value = sprintf "%g|c", $amount;

   $self->send( { $meta->{name} => $value }, $meta->{labels}, \@labelvalues );
}

*make_distribution = \&_make;

sub report_distribution
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   # A distribution acts like two counters; `sum` a `count`.

   my $meta = $self->{metrics}{$handle} or croak "No metric '$handle'";

   my $value = sprintf "%g|c", $amount;

   $self->send( {
         "$meta->{name}.sum"   => $value,
         "$meta->{name}.count" => "1|c",
      }, $meta->{labels}, \@labelvalues );
}

*inc_distribution_by = \&report_distribution;

*make_gauge = \&_make;

sub inc_gauge_by
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   my $meta = $self->{metrics}{$handle} or croak "No metric '$handle'";
   my $name = $meta->{name};

   my @value;
   push @value, "0|g" unless $self->{gauge_initialised}{$name};
   push @value, sprintf( "%+g|g", $amount );

   $self->send( { $name => \@value }, $meta->{labels}, \@labelvalues );
   $self->{gauge_initialised}{$name} = 1;
}

sub set_gauge_to
{
   my $self = shift;
   my ( $handle, $amount, @labelvalues ) = @_;

   my $meta = $self->{metrics}{$handle} or croak "No metric '$handle'";
   my $name = $meta->{name};

   my @value;
   # wire format interprets a leading - as a decrement request; so negative
   # absolute values must first set zero
   push @value, "0|g" if $amount < 0;
   push @value, sprintf( "%g|g", $amount );

   $self->send( { $name => \@value }, $meta->{labels}, \@labelvalues );
   $self->{gauge_initialised}{$name} = 1;
}

*make_timer = \&_make;

sub report_timer
{
   my $self = shift;
   my ( $handle, $duration, @labelvalues ) = @_;

   my $meta = $self->{metrics}{$handle} or croak "No metric '$handle'";

   my $value = sprintf "%d|ms", $duration * 1000; # msec

   $self->send( { $meta->{name} => $value }, $meta->{labels}, \@labelvalues );
}

*inc_timer_by = \&report_timer;

=head1 TODO

=over 4

=item *

Support non-one samplerates; emit only one-in-N packets with the C<@rate>
notation in the packet.

=item *

Optionally support one dimension of labelling by appending the conventional
C<some.metric.by_$label.$value> notation to it.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
