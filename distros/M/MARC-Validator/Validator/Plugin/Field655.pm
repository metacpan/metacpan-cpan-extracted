package MARC::Validator::Plugin::Field655;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Data::MARC::Validator::Report::Error 0.02;
use Data::MARC::Validator::Report::Plugin::Errors 0.02;
use English;
use Error::Pure::Utils qw(err_get);
use MARC::Leader 0.08;
use MARC::Field008;
use MARC::Validator::Const;

our $VERSION = 0.13;

sub module_name {
	my $self = shift;

	return __PACKAGE__;
}

sub name {
	my $self = shift;

	return 'field_655';
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
		$self->_process_errors($record_id, @record_errors);
		return;
	}

	my $field_655 = $marc_record->field('655');
	if (defined $field_655) {
		my $field_655a = $field_655->subfield('a');
		if (defined $field_655a) {
			my $material = $field_008->material;
			my $lang = $marc_record->subfield('040', 'b');
			my $qr;
			if (defined $lang
				&& exists $MARC::Validator::Const::FIELD_655{$lang}) {

				$qr = $MARC::Validator::Const::FIELD_655{$lang};
			}
			if ($material->isa('Data::MARC::Field008::Book')
				&& defined $qr
				&& $field_655a =~ $qr
				&& $material->nature_of_content !~ '6') {

				push @record_errors, Data::MARC::Validator::Report::Error->new(
					'error' => 'Missing comics nature of content in field 008.',
					'params' => {
						'field_008_nature_of_content' => $material->nature_of_content,
						'field_655_a' => $field_655a,
						'material' => 'book',
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
