package MARC::Validator::Plugin::Field040;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use MARC::Leader;
use MARC::Validator::Utils qw(add_error);

our $VERSION = 0.05;

sub name {
	my $self = shift;

	return 'field_040';
}

sub process {
	my ($self, $marc_record) = @_;

	my $struct_hr = $self->{'struct'}->{'checks'};

	my $cnb = $marc_record->field('015')->subfield('a');

	my $leader_string = $marc_record->leader;
	my $leader = MARC::Leader->new(
		'verbose' => $self->{'verbose'},
	)->parse($leader_string);

	my $desc_conventions = $marc_record->field('040')->subfield('e');

	if ($leader->descriptive_cataloging_form eq 'a'
		&& defined $desc_conventions
		&& $desc_conventions eq 'rda') {

		add_error($cnb, $struct_hr, {
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
