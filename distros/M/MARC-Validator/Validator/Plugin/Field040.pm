package MARC::Validator::Plugin::Field040;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Data::MARC::Validator::Report::Error 0.02;
use Data::MARC::Validator::Report::Plugin::Errors 0.02;
use English;
use Error::Pure::Utils qw(err_get);
use MARC::Leader 0.08;

our $VERSION = 0.15;

sub module_name {
	my $self = shift;

	return __PACKAGE__;
}

sub name {
	my $self = shift;

	return 'field_040';
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

	my $field_040 = $marc_record->field('040');
	if (! defined $field_040) {
		push @record_errors, Data::MARC::Validator::Report::Error->new(
			'error' => "Field 040 isn't present.",
		);
		$self->_process_errors($record_id, @record_errors);
		return;
	}

	if (! $field_040->subfield('a')) {
		push @record_errors, Data::MARC::Validator::Report::Error->new(
			'error' => "Subfield 040a doesn't exists.",
		);
	}

	my $desc_conventions = $field_040->subfield('e');
	if ($leader->descriptive_cataloging_form eq 'a'
		&& defined $desc_conventions
		&& $desc_conventions eq 'rda') {

		push @record_errors, Data::MARC::Validator::Report::Error->new(
			'error' => 'Leader descriptive cataloging form (a) is inconsistent with field 040e description conventions (rda).',
		);
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
