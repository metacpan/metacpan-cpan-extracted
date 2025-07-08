package Geo::Coder::Free::Display::meta_data;

use strict;
use warnings;

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

# Display the meta-data page - the internal status of the server and VWF system

use Geo::Coder::Free::Display;

our @ISA = ('Geo::Coder::Free::Display');

sub html
{
	my $self = shift;
        my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $vwf_log = $args{'vwf_log'};
	my $domain_name = $self->{'info'}->domain_name();

	my $datapoints;
	foreach my $type('web', 'mobile', 'search', 'robot') {
		my @entries = $vwf_log->type({ domain_name => $domain_name, type => $type });
		$datapoints .= '{y: ' . scalar(@entries) . ", label: \"$type\"},\n";
		if($self->{'logger'}) {
			$self->{'logger'}->debug("$type = " . scalar(@entries));
		}
	}

	return $self->SUPER::html({ datapoints => $datapoints });
}

1;
