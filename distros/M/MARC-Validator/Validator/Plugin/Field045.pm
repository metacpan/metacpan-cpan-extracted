package MARC::Validator::Plugin::Field045;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Data::MARC::Validator::Report::Error 0.02;
use Data::MARC::Validator::Report::Plugin::Errors 0.02;

our $VERSION = 0.15;

sub module_name {
	my $self = shift;

	return __PACKAGE__;
}

sub name {
	my $self = shift;

	return 'field_045';
}

sub process {
	my ($self, $marc_record) = @_;

	my $record_id = $self->{'cb_record_id'}->($marc_record);
	my @record_errors;

	my $field_045 = $marc_record->field('045');
	if (defined $field_045) {
		my $field_045a = $field_045->subfield('a');
		if (length($field_045a) != 4) {
			push @record_errors, Data::MARC::Validator::Report::Error->new(
				'error' => "Field 045a has bad length.",
			);
		}
		my $field_045a_first = substr $field_045a, 0, 2;
		my $field_045a_second = substr $field_045a, 2, 2;
		push @record_errors, $self->_check_time_period_code($field_045a_first, 'first');
		push @record_errors, $self->_check_time_period_code($field_045a_second, 'second');
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

sub _check_time_period_code {
	my ($self, $input, $resolution) = @_;

	if ($input !~ m/^[abcdefghijklmnopqrstuvwxy][\-\d]$/ms) {
		return Data::MARC::Validator::Report::Error->new(
			'error' => "Field 045a has invalid $resolution block.",
			'params' => {
				'value' => $input,
			},
		);
	}

	return ();
}

1;

__END__
