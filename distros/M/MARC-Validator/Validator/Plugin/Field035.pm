package MARC::Validator::Plugin::Field035;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use English;
use MARC::Validator::Utils qw(add_error);

our $VERSION = 0.07;

sub name {
	my $self = shift;

	return 'field_035';
}

sub process {
	my ($self, $marc_record) = @_;

	my $struct_hr = $self->{'struct'}->{'checks'};

	my $error_id = $self->{'cb_error_id'}->($marc_record);

	my @system_control_numbers = $marc_record->field('035');
	foreach my $system_control_number (@system_control_numbers) {
		my $value = $system_control_number->subfield('a');
		if (! defined $value) {
			next;
		}

		if (! exists $self->{'struct'}->{'ids'}->{$value}) {
			$self->{'struct'}->{'ids'}->{$value} = $error_id;
		} else {
			add_error($error_id, $struct_hr, {
				'error' => 'Bad system control number in 035a field.',
				'params' => {
					'value' => $value,
					'duplicate_to' => $self->{'struct'}->{'ids'}->{$value},
				},
			});
		}
	}

	return;
}

sub _init {
	my $self = shift;

	$self->{'struct'}->{'module_name'} = __PACKAGE__;
	$self->{'struct'}->{'module_version'} = $VERSION;

	$self->{'struct'}->{'checks'}->{'not_valid'} = {};

	$self->{'struct'}->{'ids'} = {};

	return;
}

1;

__END__
