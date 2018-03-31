package Geo::Coder::Free::DB::OpenAddr;

use strict;
use warnings;

# The data are from http://results.openaddresses.io/

use Geo::Coder::Free::DB;

our @ISA = ('Geo::Coder::Free::DB');

sub _open {
	my $self = shift;

	return $self->SUPER::_open(sep_char => ',', column_names => ['lon', 'lat', 'number', 'street', 'unit', 'city', 'district', 'region', 'postcode', 'id', 'hash']);
}

1;
