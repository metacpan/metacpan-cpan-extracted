use strict;
use warnings;

use Carp;


=head1 NAME

Device::CableModem::Zoom5341::Get

=head1 NOTA BENE

This is part of the guts of Device::CableModem::Zoom5341.  If you're
reading this, you're either developing the module, writing tests, or
coloring outside the lines; consider yourself warned.

=cut


=head2 ->get_down_stats

Return all the downstream stats as a hashref.
=cut
sub get_down_stats
{
	my $self = shift;

	$self->parse_conn_stats unless $self->{conn_stats};
	croak "No downstats" unless $self->{conn_stats}{down};
	return $self->{conn_stats}{down};
}

=head2 ->get_up_stats

Return all the upstream stats as a hashref.
=cut
sub get_up_stats
{
	my $self = shift;

	$self->parse_conn_stats unless $self->{conn_stats};
	croak "No upstats" unless $self->{conn_stats}{up};
	return $self->{conn_stats}{up};
}


=head2 ->get_down_freq

Return an arrayref of downstream frequencies.

=head2 ->get_down_mod

Return an arrayref of downstream modulation schemata.

=head2 ->get_down_power

Return an arrayref of downstream power levels (dBmV).

=head2 ->get_down_snr

Return an arrayref of downstream SNRs (dB).
=cut

for my $k (qw(freq mod power snr))
{
	no strict 'refs';
	*{"get_down_$k"} = sub {
		my $self = shift;
		$self->parse_conn_stats unless $self->{conn_stats};
		croak "No down ${k}stats" unless $self->{conn_stats}{down}{$k};
		return $self->{conn_stats}{down}{$k};
	};
}


=head2 ->get_up_chanid

Return an arrayref of upstream channel ids.

=head2 ->get_up_freq

Return an arrayref of upstream frequencies.

=head2 ->get_up_bw

Return an arrayref of upstream bandwidths (in the physical sense of the
width of the channel, not the logical sense of a data rate).

=head2 ->get_up_power

Return an arrayref of upstream power levels (dBmV).
=cut

for my $k (qw(chanid freq bw power))
{
	no strict 'refs';
	*{"get_up_$k"} = sub {
		my $self = shift;
		$self->parse_conn_stats unless $self->{conn_stats};
		croak "No up ${k}stats" unless $self->{conn_stats}{up}{$k};
		return $self->{conn_stats}{up}{$k};
	};
}



1;
__END__

=head1 SEE ALSO

You should probably be looking at L<Device::CableModem::Zoom5341>
instead.
