package MARC::Validator::Plugin::Field035;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Data::MARC::Validator::Report::Error 0.02;
use Data::MARC::Validator::Report::Plugin::Errors 0.02;
use English;

our $VERSION = 0.13;

sub module_name {
	my $self = shift;

	return __PACKAGE__;
}

sub name {
	my $self = shift;

	return 'field_035';
}

sub process {
	my ($self, $marc_record) = @_;

	my $record_id = $self->{'cb_record_id'}->($marc_record);
	my @record_errors;

	my @system_control_numbers = $marc_record->field('035');
	foreach my $system_control_number (@system_control_numbers) {
		my $value = $system_control_number->subfield('a');
		if (! defined $value) {
			next;
		}

		if (! exists $self->{'ids'}->{$value}) {
			$self->{'ids'}->{$value} = $record_id;
		} elsif ($self->{'ids'}->{$value} eq $record_id) {
			push @record_errors, Data::MARC::Validator::Report::Error->new(
				'error' => 'Duplicate system control number in 035a field.',
				'params' => {
					'Value' => $value,
				},
			);
		} else {
			push @record_errors, Data::MARC::Validator::Report::Error->new(
				'error' => 'Bad system control number in 035a field.',
				'params' => {
					'value' => $value,
					'duplicate_to' => $self->{'ids'}->{$value},
				},
			);
		}
	}

	if (@record_errors) {
		push @{$self->{'errors'}},  Data::MARC::Validator::Report::Plugin::Errors->new(
			'errors' => \@record_errors,
			'filters' => $self->{'filters'},
			'record_id' => $record_id,
		);
	}

	return;
}

sub version {
	my $self = shift;

	return $VERSION;
}

sub _init {
	my $self = shift;

	$self->{'ids'} = {};

	return;
}

1;

__END__
