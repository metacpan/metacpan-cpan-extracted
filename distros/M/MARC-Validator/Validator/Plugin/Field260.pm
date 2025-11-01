package MARC::Validator::Plugin::Field260;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use MARC::Validator::Utils qw(check_260c_year);

our $VERSION = 0.06;

sub name {
	my $self = shift;

	return 'field_260';
}

sub process {
	my ($self, $marc_record) = @_;

	my $struct_hr = $self->{'struct'}->{'checks'};

	my $error_id = $self->{'cb_error_id'}->($marc_record);

	my @field_260 = $marc_record->field('260');
	foreach my $field_260 (@field_260) {
		my @field_260_c = $field_260->subfield('c');
		foreach my $field_260_c (@field_260_c) {
			check_260c_year($self, $field_260_c, $struct_hr, $error_id, '260');
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
