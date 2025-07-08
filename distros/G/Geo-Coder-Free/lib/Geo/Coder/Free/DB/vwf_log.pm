package Geo::Coder::Free::DB::vwf_log;

use strict;
use warnings;

=head1 NAME

Geo::Coder::Free::DB::vwf_log - Driver for /tmp/vwf.log

=head1 VERSION

Version 0.41

=cut

our $VERSION = '0.41';

use Database::Abstraction;
use DBD::CSV;

our @ISA = ('Database::Abstraction');

# Standard CSV file, with no header line

# Doesn't ignore lines starting with '#' as it's not treated like a CSV file
sub _open {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return $self->SUPER::_open(sep_char => ',', column_names => ['domain_name', 'time', 'IP', 'country', 'type', 'language', 'http_code', 'template', 'args', 'warnings', 'error'], %args);
}

1;
