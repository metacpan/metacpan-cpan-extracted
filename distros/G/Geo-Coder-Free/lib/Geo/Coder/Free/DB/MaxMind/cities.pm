package Geo::Coder::Free::DB::MaxMind::cities;

use strict;
use warnings;
use autodie qw(:all);

=head1 NAME

Geo::Coder::Free::DB::MaxMind::cities - driver for https://www.maxmind.com/en/free-world-cities-database

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use parent 'Database::Abstraction';

sub _open {
	my $self = shift;

	return $self->SUPER::_open(sep_char => ',');
}

1;
