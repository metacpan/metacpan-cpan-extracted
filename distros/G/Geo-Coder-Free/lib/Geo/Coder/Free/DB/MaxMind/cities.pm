package Geo::Coder::Free::DB::MaxMind::cities;

use strict;
use warnings;

=head1 NAME

Geo::Coder::Free::DB::MaxMind::cities - driver for https://www.maxmind.com/en/free-world-cities-database

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

use Database::Abstraction;

our @ISA = ('Database::Abstraction');

sub _open {
	my $self = shift;

	return $self->SUPER::_open(sep_char => ',');
}

1;
