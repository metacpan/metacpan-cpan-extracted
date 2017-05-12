# Fetch page from the cablemodem
use strict;
use warnings;

use Carp;


=head1 NAME

Device::CableModem::Zoom5341J::Fetch

=head1 NOTA BENE

This is part of the guts of Device::CableModem::Zoom5341J.  If you're
reading this, you're either developing the module, writing tests, or
coloring outside the lines; consider yourself warned.

=cut


=head2 ->fetch_page_rows

Grabs the connection status page from the modem, returns the given HTML.
=cut

# The URL's we grab
my $login_url = '/login.asp';
my $login_post = '/goform/login';
my $conn_url = '/RgConnect.asp';

use LWP::UserAgent;
use HTTP::Request::Common qw/POST/;
sub fetch_page_rows
{
	my $self = shift;

	my $ua = LWP::UserAgent->new;

	my @uerrs;
	my $ubase = "http://$self->{modem_addr}";

	# It seems like we have to have hit the base page first, or it fails
	# us logging in...
	$ua->get("$ubase/");

	# POST to the login page
	my $res = $ua->post("${ubase}${login_post}", Content => {
			loginUsername => $self->{username},
			loginPassword => $self->{password},
	});
	croak "Expected redirect, not $res->code"
			unless $res->code == 302;

	my $rloc = $res->header('Location');
	croak "No redirect header location" unless $rloc;
	croak "Login failed" unless $rloc =~ m#$conn_url#;


	# Login succeeded.  Go ahead and grab the connection stats.
	my $url = "${ubase}${conn_url}";
	$res = $ua->get($url);
	croak "Stat page request to $url failed" unless $res->is_success;
	my $html = $res->content;
	croak "Got no data from $url" unless $html;

	return $html;
}


=head2 ->fetch_data

Grabs and stashes the data.
=cut
sub fetch_data
{
	my $self = shift;

	# Ensure everything's clear
	$self->{conn_html}  = undef;
	$self->{conn_stats} = undef;

	# Backdoor for testing
	return if $self->{__TESTING_NO_FETCH};

	my $html = $self->fetch_page_rows;
	carp "Failed fetching page from modem" unless $html;
	$self->{conn_html} = $html;

	return;
}


1;
__END__

=head1 SEE ALSO

You should probably be looking at L<Device::CableModem::Zoom5341J>
instead.
