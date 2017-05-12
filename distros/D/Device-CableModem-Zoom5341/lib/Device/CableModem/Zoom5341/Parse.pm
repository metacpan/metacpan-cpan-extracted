use strict;
use warnings;

use Carp;


=head1 NAME

Device::CableModem::Zoom5341::Parse

=head1 NOTA BENE

This is part of the guts of Device::CableModem::Zoom5341.  If you're
reading this, you're either developing the module, writing tests, or
coloring outside the lines; consider yourself warned.

=cut


=head2 ->parse_connrow_vals

Parses out stuff from connection status rows related to up/downstream
stats.
=cut
sub parse_connrow_vals
{
	my $self = shift;
	my $str = shift;

	croak "No HTML stashed" unless $self->{conn_html};

	# Find the JS row
	my @row = grep /^var $str = /, @{$self->{conn_html}};
	croak "Bad row results for '$str'" unless @row == 1;

	# Pull out just the string
	my ($sval) = ($row[0] =~ /"([^"]+)";/);

	# And return it split on pipes
	my @flds = split /\|/, $sval;
	return \@flds;
}


=head2 ->parse_conn_stats

Parse out all the connection status bits.
=cut
sub parse_conn_stats
{
	my $self = shift;

	$self->fetch_connection unless $self->{conn_html};
	croak "No HTML stashed" unless $self->{conn_html};

	# First grab all the data out of the JS bits
	my %dbits = (
		freq   => 'CmDownstreamFrequencyBase',
		mod    => 'CmDownstreamQamBase',
		power  => 'CmDownstreamChannelPowerdBmVBase',
		snr    => 'CmDownstreamSnrBase',
	);
	my %ubits = (
		chanid => 'CmUpstreamChannelIdBase',
		freq   => 'CmUpstreamFrequencyBase',
		bw     => 'CmUpstreamBwBase',
		power  => 'CmUpstreamChannelPowerBase',
	);

	$self->{conn_stats}{down}{$_} = $self->parse_connrow_vals($dbits{$_})
			for keys %dbits;
	$self->{conn_stats}{up}{$_} = $self->parse_connrow_vals($ubits{$_})
			for keys %ubits;


	# Now empty out up/down channels as necessary
	my $ds = $self->{conn_stats}{down};
	for my $i (0..$#{$ds->{freq}})
	{
		unless($ds->{freq}[$i] > 0)
		{
			undef($ds->{$_}[$i]) for keys %dbits
		}
	}

	my $us = $self->{conn_stats}{up};
	for my $i (0..$#{$us->{chanid}})
	{
		unless($us->{chanid}[$i] > 0)
		{
			undef($us->{$_}[$i]) for keys %ubits
		}
	}

	return;
}


1;
__END__

=head1 SEE ALSO

You should probably be looking at L<Device::CableModem::Zoom5341>
instead.
