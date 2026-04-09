package MARC::Validator::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Data::MARC::Validator::Report::Error 0.02;
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_260c_year);

our $VERSION = 0.15;

sub check_260c_year {
	my ($self, $value, $field) = @_;

	if ($value =~ m/^\(\d+\)$/ms) {
		return Data::MARC::Validator::Report::Error->new(
			'error' => 'Bad year in parenthesis in MARC field '.$field.' $c.',
			'params' => {
				'Value' => $value,
			},
		);
	}

	return ();
}

1;

__END__
