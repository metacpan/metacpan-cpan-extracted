package Geo::Coder::Free::DB::OpenAddr;

use strict;
use warnings;
use Database::Abstraction;

=head1 NAME

Geo::Coder::Free::DB::Free::OpenAddr - driver for http://results.openaddresses.io/

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

our @ISA = ('Database::Abstraction');

sub _open {
	my $self = shift;

	return $self->SUPER::_open(sep_char => ',', column_names => ['lon', 'lat', 'number', 'street', 'unit', 'city', 'district', 'region', 'postcode', 'id', 'hash']);
}

1;
