package MARC::Validator::Plugin::Field008;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use English;
use Error::Pure::Utils qw(err_get);
use MARC::Leader;
use MARC::Field008;

our $VERSION = 0.07;

sub name {
	my $self = shift;

	return 'field_008';
}

sub process {
	my ($self, $marc_record) = @_;

	my $struct_hr = $self->{'struct'}->{'checks'};

	my $error_id = $self->{'cb_error_id'}->($marc_record);

	my $leader_string = $marc_record->leader;
	my $leader = eval {
		MARC::Leader->new(
			'verbose' => $self->{'verbose'},
		)->parse($leader_string);
	};
	if ($EVAL_ERROR) {
		my @errors = err_get(1);
		$struct_hr->{'not_valid'}->{$error_id} = [];
		foreach my $error (@errors) {
			my %err_params = @{$error->{'msg'}}[1 .. $#{$error->{'msg'}}];
			push @{$struct_hr->{'not_valid'}->{$error_id}}, {
				'error' => $error->{'msg'}->[0],
				'params' => \%err_params,
			};
		}
		return;
	}

	my $field_008_obj = $marc_record->field('008');
	if (! defined $field_008_obj) {
		push @{$struct_hr->{'not_valid'}->{$error_id}}, {
			'error' => 'Field 008 is not present.',
		};
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
		$struct_hr->{'not_valid'}->{$error_id} = [];
		foreach my $error (@errors) {
			my %err_params = @{$error->{'msg'}}[1 .. $#{$error->{'msg'}}];
			push @{$struct_hr->{'not_valid'}->{$error_id}}, {
				'error' => $error->{'msg'}->[0],
				'params' => \%err_params,
			};
		}

	# Parsing of field 008 is valid, other checks.
	} else {
		if ($field_008->type_of_date eq 's') {
			if ($field_008->date1 eq '    ') {
				$struct_hr->{'not_valid'}->{$error_id} = [{
					'error' => 'Field 008 date 1 need to be fill.',
					'params' => {
						'Value', $field_008_string,
					},
				}];
			} else {
				if ($field_008->date1 eq $field_008->date2) {
					$struct_hr->{'not_valid'}->{$error_id} = [{
						'error' => 'Field 008 date 1 is same as date 2.',
						'params' => {
							'Value', $field_008_string,
						},
					}];
				}
			}
		}
	}

	return;
}

sub _init {
	my $self = shift;

	$self->{'struct'}->{'module_name'} = __PACKAGE__;
	$self->{'struct'}->{'module_version'} = $VERSION;

	$self->{'struct'}->{'checks'}->{'not_valid'} = {};

	return;
}

1;

__END__
