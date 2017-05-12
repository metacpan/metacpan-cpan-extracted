use strict;
use warnings;

use Carp;


=head1 NAME

Device::CableModem::Zoom5341J::Parse

=head1 NOTA BENE

This is part of the guts of Device::CableModem::Zoom5341J.  If you're
reading this, you're either developing the module, writing tests, or
coloring outside the lines; consider yourself warned.

=cut


=head2 ->parse_conn_stats

Parse out all the connection status bits.
=cut
sub parse_conn_stats
{
	my $self = shift;

	$self->fetch_data unless $self->{conn_html};
	croak "No HTML stashed" unless $self->{conn_html};

	# First extract out a fragment that contains all the downstream and
	# upstream data
	my ($dsfrag) = ($self->{conn_html} =~
			m#Downstream Bonded Channels(.+?)</table>#s);
	croak "Couldn't find downstream fragment" unless $dsfrag;
	chomp(my @dslines = split /\n/, $dsfrag);

	my ($usfrag) = ($self->{conn_html} =~
			m#Upstream Bonded Channels(.+?)</table>#s);
	croak "Couldn't find upstream fragment" unless $usfrag;
	chomp(my @uslines = split /\n/, $usfrag);


	# Make life easier on regexen
	my $td = "<td[^>]*>\\s*";
	my $etd = "\\s*</td>";

	# Go through the downstream lines, grabbing the stat bits
	my %dsstat;
	for my $l (@dslines)
	{
		# Grab all the table cells in a line
		my @tds = ($l =~ m#$td(.*?)$etd#g);
		next unless @tds;

		# First should be a channel number
		next unless $tds[0] =~ m#^\d+$#;

		# Grab the bits we care about
		my ($chanid) = $tds[0];
		my ($mod)    = $tds[2];
		my ($freq)   = ($tds[4] =~ m#(\d+) Hz#);
		my ($power)  = ($tds[5] =~ m#([\d.]+) dBmV#);
		my ($snr)    = ($tds[6] =~ m#([\d.]+) dB#);

		# And stash them
		push @{$dsstat{chanid}}, $chanid;
		push @{$dsstat{mod}},    $mod;
		push @{$dsstat{freq}},   $freq;
		push @{$dsstat{power}},  $power;
		push @{$dsstat{snr}},    $snr;
	}

	$self->{conn_stats}{down} = \%dsstat;


	# Now do the same for upstream
	my %usstat;
	for my $l (@uslines)
	{
		# Grab all the table cells in a line
		my @tus = ($l =~ m#$td(.*?)$etd#g);
		next unless @tus;

		# First should be a channel number
		next unless $tus[0] =~ m#^\d+$#;

		# Grab the bits we care about
		my ($chanid) = $tus[0];
		my ($bw)     = ($tus[4] =~ m#(\d+) Ksym/sec#);
		my ($freq)   = ($tus[5] =~ m#(\d+) Hz#);
		my ($power)  = ($tus[6] =~ m#([\d.]+) dBmV#);

		# And stash them
		push @{$usstat{chanid}}, $chanid;
		push @{$usstat{bw}},     $bw;
		push @{$usstat{freq}},   $freq;
		push @{$usstat{power}},  $power;
	}

	$self->{conn_stats}{up} = \%usstat;


	# Now empty out up/down channels as necessary
	my $ds = $self->{conn_stats}{down};
	for my $i (0..$#{$ds->{freq}})
	{
		unless($ds->{freq}[$i] && $ds->{freq}[$i] > 0)
		{
			undef($ds->{$_}[$i]) for keys %$ds;
		}
	}

	my $us = $self->{conn_stats}{up};
	for my $i (0..$#{$us->{chanid}})
	{
		unless($us->{freq}[$i] && $us->{freq}[$i] > 0)
		{
			undef($us->{$_}[$i]) for keys %$us;
		}
	}

	return;
}


1;
__END__

=head1 SEE ALSO

You should probably be looking at L<Device::CableModem::Zoom5341J>
instead.
