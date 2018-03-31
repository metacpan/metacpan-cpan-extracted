package Geo::Coder::Free::Display::query;

use strict;
use warnings;
use JSON;

# Run a query on the database

use Geo::Coder::Free::Display;

our @ISA = ('Geo::Coder::Free::Display');

sub html {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $info = $self->{_info};
	my $allowed = {
		'page' => 'query',
		'q' => undef,	# TODO: regex of allowable name formats
		'lang' => qr/^[A-Z][A-Z]/i,
	};
	my %params = %{$info->params({ allow => $allowed })};

	# TODO: check requested format (JSON/XML) and return that

	delete $params{'page'};
	delete $params{'lang'};

	my $geocoder = $args{'geocoder'};

	my $q = $params{'q'};

	return '{ }' if(!defined($q));

	my $rc = $geocoder->geocode(location => $q);

	return '{ }' if(!defined($rc));

	return encode_json $rc;
}

1;
