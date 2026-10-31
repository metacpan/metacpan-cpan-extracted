package Geo::Coder::Free::DB::vwf_log;

use strict;
use warnings;
use autodie qw(:all);

=head1 NAME

Geo::Coder::Free::DB::vwf_log - Driver for /tmp/vwf.log

=head1 VERSION

Version 0.52

=cut

our $VERSION = '0.52';

use parent 'Database::Abstraction';
use DBD::CSV;
use Params::Get;

# Standard CSV file, with no header line

# Doesn't ignore lines starting with '#' as it's not treated like a CSV file
sub _open {
	my $self = shift;
	my $args = Params::Get::get_params(undef, @_);

	return $self->SUPER::_open(
		sep_char     => ',',
		column_names => ['domain_name', 'time', 'IP', 'country', 'type', 'language', 'http_code', 'template', 'args', 'warnings', 'error'],
		%{$args}
	);
}

1;
