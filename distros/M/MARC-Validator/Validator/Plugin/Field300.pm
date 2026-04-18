package MARC::Validator::Plugin::Field300;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Data::MARC::Validator::Report::Error 0.02;
use Data::MARC::Validator::Report::Plugin::Errors 0.02;
use English;
use Error::Pure::Utils qw(clean);
use List::Util 1.33 qw(any);
use MARC::Leader 0.08;
use MARC::Field008;
use MARC::Validator::Const;

our $VERSION = 0.17;

sub module_name {
	my $self = shift;

	return __PACKAGE__;
}

sub name {
	my $self = shift;

	return 'field_300';
}

sub process {
	my ($self, $marc_record) = @_;

	my $record_id = $self->{'cb_record_id'}->($marc_record);
	my @record_errors;
	my @record_errors_recomm;

	my $leader_string = $marc_record->leader;
	my $leader = eval {
		MARC::Leader->new(
			'verbose' => $self->{'verbose'},
		)->parse($leader_string);
	};
	if ($EVAL_ERROR) {
		clean();
		return;
	}

	my $field_008_obj = $marc_record->field('008');
	if (! defined $field_008_obj) {
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
		clean();
		return;
	}

	my @field_300 = $marc_record->field('300');
	foreach my $field_300 (@field_300) {
		my $field_300a = $field_300->subfield('a');
		if (defined $field_300a) {
			my $bad_string;
			if (any { ($bad_string) = $field_300a =~ m/($_)/ms }
				@MARC::Validator::Const::FIELD_300ab_BAD) {

				push @record_errors, Data::MARC::Validator::Report::Error->new(
					'error' => 'Bad string in field 300a.',
					'params' => {
						'bad_string' => $bad_string,
						'field_300_a' => $field_300a,
					},
				);
			}
		}
		my $field_300b = $field_300->subfield('b');
		if (defined $field_300b) {
			my $material = $field_008->material;
			my $bad_string;
			if (any { ($bad_string) = $field_300b =~ m/($_)/ms }
				@MARC::Validator::Const::FIELD_300ab_BAD) {

				push @record_errors, Data::MARC::Validator::Report::Error->new(
					'error' => 'Bad string in field 300b.',
					'params' => {
						'bad_string' => $bad_string,
						'field_300_b' => $field_300b,
					},
				);

			# Continue with checks.
			} elsif ($material->isa('Data::MARC::Field008::Book')) {
				if ($material->illustrations eq '    ') {
					push @record_errors, Data::MARC::Validator::Report::Error->new(
						'error' => 'Missing ilustrations in field 008.',
						'params' => {
							'field_008_illustrations' => $material->illustrations,
							'field_300_b' => $field_300b,
							'material' => 'book',
						},
					);
					last;
				} elsif ($material->illustrations eq '||||') {
					if ($self->{'recommendation'}) {
						push @record_errors_recomm, Data::MARC::Validator::Report::Error->new(
							'error' => 'Recommended ilustrations in field 008.',
							'params' => {
								'field_008_illustrations' => $material->illustrations,
								'field_300_b' => $field_300b,
								'material' => 'book',
							},
						);
						last;
					}
				}
			}
		}
	}

	if (@record_errors) {
		push @{$self->{'errors'}}, Data::MARC::Validator::Report::Plugin::Errors->new(
			'errors' => \@record_errors,
			'filters' => $self->{'filters'},
			'record_id' => $record_id,
		);
	}
	if (@record_errors_recomm) {
		push @{$self->{'errors'}}, Data::MARC::Validator::Report::Plugin::Errors->new(
			'errors' => \@record_errors_recomm,
			'filters' => [@{$self->{'filters'}}, 'recommendation'],
			'record_id' => $record_id,
		);
	}

	return;
}

sub version {
	my $self = shift;

	return $VERSION;
}

1;

__END__
