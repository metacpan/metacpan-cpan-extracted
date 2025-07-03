package MARC::Validator::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_260c_year);

our $VERSION = 0.01;

sub check_260c_year {
	my ($self, $value, $struct_hr, $cnb, $field) = @_;

	if ($value =~ m/^\(\d+\)$/ms) {
		if (! exists $struct_hr->{'not_valid'}->{$cnb}) {
			$struct_hr->{'not_valid'}->{$cnb} = [];
		}
		push @{$struct_hr->{'not_valid'}->{$cnb}}, {
			'error' => 'Bad year in parenthesis in MARC field '.$field.' $c.',
			'params' => {
				'Value' => $value,
			},
		};
	}

	return;
}

1;

__END__
