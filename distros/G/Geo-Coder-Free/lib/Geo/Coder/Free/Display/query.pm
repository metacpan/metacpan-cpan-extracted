package Geo::Coder::Free::Display::query;

# Run a query on the database

use strict;
use warnings;
use autodie qw(:all);

use Carp;

=head1 VERSION

Version 0.47

=cut

our $VERSION = '0.47';

use parent 'Geo::Coder::Free::Display';
use JSON::MaybeXS;

sub html {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $info = $self->{_info};
	Carp::croak('no _info') unless $info;

	my $allowed = {
		'page'     => 'query',
		# Addresses: letters (including accented), digits, spaces, and common
		# punctuation.  Angle brackets are excluded to prevent XSS in any
		# error path that echoes the input.  500-char cap prevents DoS via
		# absurdly long strings reaching the geocoder.
		'q'        => qr/^[^<>\x00-\x1f\x7f]{1,500}$/,
		# Free text for scantext mode — allow anything printable but cap
		# length so the geocoder's O(N²) word-window scan stays bounded.
		'scantext' => qr/^[^\x00-\x08\x0b\x0c\x0e-\x1f\x7f]{1,2000}$/,
		'lang'     => qr/^[A-Z]{2}/i,
	};
	my %params = %{$info->params({ allow => $allowed })};

	# TODO: check requested format (JSON/XML) and return that

	delete $params{'page'};
	delete $params{'lang'};

	my $geocoder = $args{'geocoder'};

	my $rc;
	if(my $q = $params{'q'}) {
		$rc = $geocoder->geocode(location => $q);

		if(!defined($rc)) {
			# Maybe the user didn't give a country, so let's add it
			# and search again
			if(my $country = $self->{_lingua}->country()) {
				$rc = $geocoder->geocode(location => "$q, $country");
			}
			return '{}' if(!defined($rc));
		}

		return encode_json {
			'latitude'  => $rc->lat(),
			'longitude' => $rc->long()
		};
	} elsif(my $scantext = $params{'scantext'}) {
		my @rc = $geocoder->geocode(scantext => $scantext);

		if(scalar(@rc) > 0) {
			my @locations;
			foreach my $l(@rc) {
				push @locations, {
					'latitude'  => $l->lat(),
					'longitude' => $l->long()
				};
			}
			return encode_json \@locations;
		}
	}

	return '{}';
}

1;
