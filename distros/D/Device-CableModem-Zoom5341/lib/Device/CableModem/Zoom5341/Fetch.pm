# Fetch page from the cablemodem
use strict;
use warnings;

use Carp;


=head1 NAME

Device::CableModem::Zoom5341::Fetch

=head1 NOTA BENE

This is part of the guts of Device::CableModem::Zoom5341.  If you're
reading this, you're either developing the module, writing tests, or
coloring outside the lines; consider yourself warned.

=cut


=head2 ->fetch_page_rows

Grabs the connection status page from the modem, returns the given HTML
as an array of lines.
=cut

# The URL's have changed over time
my @urls = (
	# This one exists in SW version 3.1.0.1pre3 and possibly earlier
	'admin/cable-status.asp',

	# This one existed in older stuff, back in 2011 and for some time
	# after.
	'status_connection.asp',
);
my $url; # Chosen one for this modem

sub fetch_page_rows
{
	my $self = shift;

	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new;

	# Use the URL we already found, if we found one; otherwise try 'em
	# all.
	my @uopts = $url ? ($url) : (@urls);

	# Try each of our candidates until one succeeds or we run out
	my @uerrs;
	my $res;
	for my $u (@uopts)
	{
		$url = "http://$self->{modem_addr}/$u";
		my $req = HTTP::Request->new(GET => $url);
		$res = $ua->request($req);

		# Got it? Go ahead.
		last if $res->is_success;

		# Otherwise rack up an error, and loop back around.
		push @uerrs, "Failed HTTP GET on $url: @{[$res->status_line]}";
	}

	# If things failed, dump out all the errors
	croak join "\n", @uerrs unless $res->is_success;

	# Make sure we got actual data
	my $html = $res->content;
	croak "Got no data from $url" unless($html);

	# Put it together and hand it back.
	my @html = split /\n/, $html;
	chomp @html;

	return @html;
}


=head2 ->fetch_connection

Grabs and stashes the connection status page.
=cut
sub fetch_connection
{
	my $self = shift;

	# Ensure everything's clear
	$self->{conn_html}  = undef;
	$self->{conn_stats} = undef;

	# Backdoor for testing
	return if $self->{__TESTING_NO_FETCH};

	my @html = $self->fetch_page_rows;
	carp "Failed fetching page from modem" unless @html;
	$self->{conn_html} = \@html;

	return;
}


1;
__END__

=head1 SEE ALSO

You should probably be looking at L<Device::CableModem::Zoom5341>
instead.
