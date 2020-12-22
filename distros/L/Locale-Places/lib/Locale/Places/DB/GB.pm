package Locale::Places::DB::GB;

use strict;
use warnings;

# GB.db is from http://download.geonames.org/export/dump/alternatenames/GB.zip

use Locale::Places::DB;

our @ISA = ('Locale::Places::DB');

sub _open {
	my $self = shift;

	return $self->SUPER::_open(sep_char => "\t", column_names => ['code1','code2','type','data']);
}

1;
