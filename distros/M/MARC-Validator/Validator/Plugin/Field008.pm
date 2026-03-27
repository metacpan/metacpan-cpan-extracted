package MARC::Validator::Plugin::Field008;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Data::MARC::Validator::Report::Error 0.02;
use Data::MARC::Validator::Report::Plugin::Errors 0.02;
use English;
use Error::Pure::Utils qw(err_get);
use MARC::Leader 0.08;
use MARC::Field008;

our $VERSION = 0.14;

sub module_name {
	my $self = shift;

	return __PACKAGE__;
}

sub name {
	my $self = shift;

	return 'field_008';
}

sub process {
	my ($self, $marc_record) = @_;

	my $record_id = $self->{'cb_record_id'}->($marc_record);
	my @record_errors;

	my $leader_string = $marc_record->leader;
	my $leader = eval {
		MARC::Leader->new(
			'verbose' => $self->{'verbose'},
		)->parse($leader_string);
	};
	if ($EVAL_ERROR) {
		my @errors = err_get(1);
		foreach my $error (@errors) {
			my %err_params = @{$error->{'msg'}}[1 .. $#{$error->{'msg'}}];
			push @record_errors, Data::MARC::Validator::Report::Error->new(
				'error' => $error->{'msg'}->[0],
				'params' => \%err_params,
			);
		}
		$self->_process_errors($record_id, @record_errors);
		return;
	}

	my $field_008_obj = $marc_record->field('008');
	if (! defined $field_008_obj) {
		push @record_errors, Data::MARC::Validator::Report::Error->new(
			'error' => 'Field 008 is not present.',
		);
		$self->_process_errors($record_id, @record_errors);
		return;
	}
	my $field_008_string = $field_008_obj->as_string;
	my $field_008 = eval {
		MARC::Field008->new(
			'leader' => $leader,
			'verbose' => $self->{'verbose'},
		)->parse($field_008_string);
	};
	if ($EVAL_ERROR) {
		my @errors = err_get(1);
		foreach my $error (@errors) {
			my %err_params = @{$error->{'msg'}}[1 .. $#{$error->{'msg'}}];
			push @record_errors, Data::MARC::Validator::Report::Error->new(
				'error' => $error->{'msg'}->[0],
				'params' => \%err_params,
			);
		}

	# Parsing of field 008 is valid, other checks.
	} else {
		if ($field_008->type_of_date eq 's') {
			if ($field_008->date1 eq '    ') {
				push @record_errors, Data::MARC::Validator::Report::Error->new(
					'error' => 'Field 008 date 1 need to be fill.',
					'params' => {
						'Value' => $field_008_string,
					},
				);
			} else {
				if ($field_008->date1 eq $field_008->date2) {
					push @record_errors, Data::MARC::Validator::Report::Error->new(
						'error' => 'Field 008 date 1 is same as date 2.',
						'params' => {
							'Value' => $field_008_string,
						},
					);
				}
			}
		}

		if ($field_008->type_of_date eq 'c') {
			if ($field_008->date2 ne '9999') {
				push @record_errors, Data::MARC::Validator::Report::Error->new(
					'error' => 'Field 008 date 2 need to be 9999, it\'s currently published.',
					'params' => {
						'Value' => $field_008_string,
					},
				);
			}
		}
	}

	$self->_process_errors($record_id, @record_errors);

	return;
}

sub version {
	my $self = shift;

	return $VERSION;
}

sub _process_errors {
	my ($self, $record_id, @record_errors) = @_;

	if (@record_errors) {
		push @{$self->{'errors'}}, Data::MARC::Validator::Report::Plugin::Errors->new(
			'errors' => \@record_errors,
			'filters' => $self->{'filters'},
			'record_id' => $record_id,
		);
	}

	return;
}

1;

__END__
