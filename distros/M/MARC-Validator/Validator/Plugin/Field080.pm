package MARC::Validator::Plugin::Field080;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Business::UDC;
use Data::MARC::Validator::Report::Error 0.02;
use Data::MARC::Validator::Report::Plugin::Errors 0.02;

our $VERSION = 0.14;

sub module_name {
	my $self = shift;

	return __PACKAGE__;
}

sub name {
	my $self = shift;

	return 'field_080';
}

sub process {
	my ($self, $marc_record) = @_;

	my $record_id = $self->{'cb_record_id'}->($marc_record);
	my @record_errors;

	my @field_080 = $marc_record->field('080');
	foreach my $field_080 (@field_080) {
		my $field_080a = $field_080->subfield('a');
		my $udc = Business::UDC->new($field_080a);
		if (! $udc->is_valid) {
			if ($udc->error eq "Unexpected token ']'.") {
				push @record_errors, Data::MARC::Validator::Report::Error->new(
					'error' => "Field 080a has missing '['.",
					'params' => {
						'value' => $field_080a,
					},
				);
			} elsif ($udc->error eq "Unclosed subgroup '['.") {
				push @record_errors, Data::MARC::Validator::Report::Error->new(
					'error' => "Field 080a has missing ']'.",
					'params' => {
						'value' => $field_080a,
					},
				);
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

	return;
}

sub version {
	my $self = shift;

	return $VERSION;
}

1;

__END__
