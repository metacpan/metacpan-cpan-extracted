package MARC::Validator::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

Readonly::Array our @EXPORT_OK => qw(add_error check_260c_year);

our $VERSION = 0.08;

sub add_error {
	my ($cnb, $struct_hr, $error_hr) = @_;

	if (! exists $struct_hr->{'not_valid'}->{$cnb}) {
		$struct_hr->{'not_valid'}->{$cnb} = [];
	}
	push @{$struct_hr->{'not_valid'}->{$cnb}}, $error_hr;

	return;
}

sub check_260c_year {
	my ($self, $value, $struct_hr, $cnb, $field) = @_;

	if ($value =~ m/^\(\d+\)$/ms) {
		add_error($cnb, $struct_hr, {
			'error' => 'Bad year in parenthesis in MARC field '.$field.' $c.',
			'params' => {
				'Value' => $value,
			},
		});
	}

	return;
}

1;

__END__
