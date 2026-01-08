package MARC::Validator::Plugin::Field040;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use English;
use Error::Pure::Utils qw(err_get);
use MARC::Leader 0.08;
use MARC::Validator::Utils qw(add_error);

our $VERSION = 0.09;

sub name {
	my $self = shift;

	return 'field_040';
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

	my $field_040 = $marc_record->field('040');
	if (! defined $field_040) {
		add_error($error_id, $struct_hr, {
			'error' => "Field 040 isn't present.",
		});
		return;
	}

	if (! $field_040->subfield('a')) {
		add_error($error_id, $struct_hr, {
			'error' => "Subfield 040a doesn't exists.",
		});
	}

	my $desc_conventions = $field_040->subfield('e');
	if ($leader->descriptive_cataloging_form eq 'a'
		&& defined $desc_conventions
		&& $desc_conventions eq 'rda') {

		add_error($error_id, $struct_hr, {
			'error' => 'Leader descriptive cataloging form (a) is inconsistent with field 040e description conventions (rda).',
		});
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
