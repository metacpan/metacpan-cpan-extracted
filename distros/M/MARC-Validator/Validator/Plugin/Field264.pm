package MARC::Validator::Plugin::Field264;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use MARC::Validator::Utils qw(check_260c_year);

our $VERSION = 0.01;

sub name {
	my $self = shift;

	return 'field_264';
}

sub process {
	my ($self, $marc_record) = @_;

	my $struct_hr = $self->{'struct'}->{'checks'};

	my $cnb = $marc_record->field('015')->subfield('a');

	my @field_264 = $marc_record->field('264');
	foreach my $field_264 (@field_264) {
		my @field_264_c = $field_264->subfield('c');
		foreach my $field_264_c (@field_264_c) {
			check_260c_year($self, $field_264_c, $struct_hr, $cnb, '264');
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
