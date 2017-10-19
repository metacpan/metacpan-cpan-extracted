package Geo::Coder::Free::DB::cities;

# cities.csv is from https://www.maxmind.com/en/free-world-cities-database

use Geo::Coder::Free::DB;

our @ISA = ('Geo::Coder::Free::DB');

sub _open {
	my $self = shift;

	return $self->SUPER::_open(sep_char => ',');
}

1;
