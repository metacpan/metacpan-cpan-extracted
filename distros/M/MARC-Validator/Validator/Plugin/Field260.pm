package MARC::Validator::Plugin::Field260;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Data::MARC::Validator::Report::Error 0.02;
use Data::MARC::Validator::Report::Plugin::Errors 0.02;
use MARC::Validator::Utils qw(check_260c_year);

our $VERSION = 0.14;

sub module_name {
	my $self = shift;

	return __PACKAGE__;
}

sub name {
	my $self = shift;

	return 'field_260';
}

sub process {
	my ($self, $marc_record) = @_;

	my $record_id = $self->{'cb_record_id'}->($marc_record);
	my @record_errors;

	my @field_260 = $marc_record->field('260');
	foreach my $field_260 (@field_260) {
		my @field_260_c = $field_260->subfield('c');
		foreach my $field_260_c (@field_260_c) {
			push @record_errors, check_260c_year($self, $field_260_c, '260');
		}
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

1;

__END__
