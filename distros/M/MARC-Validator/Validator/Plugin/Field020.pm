package MARC::Validator::Plugin::Field020;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Business::ISBN;
use Data::MARC::Validator::Report::Error 0.02;
use Data::MARC::Validator::Report::Plugin::Errors 0.02;
use English;
use Error::Pure::Utils qw(err_get);

our $VERSION = 0.14;

sub module_name {
	my $self = shift;

	return __PACKAGE__;
}

sub name {
	my $self = shift;

	return 'field_020';
}

sub process {
	my ($self, $marc_record) = @_;

	my $record_id = $self->{'cb_record_id'}->($marc_record);
	my @record_errors;

	my @isbn_fields = $marc_record->field('020');
	foreach my $isbn_field (@isbn_fields) {
		my $isbn = $isbn_field->subfield('a');
		if (! defined $isbn) {
			next;
		}
		my $isbn_obj = Business::ISBN->new($isbn);
		if (! defined $isbn_obj) {
			push @record_errors, Data::MARC::Validator::Report::Error->new(
				'error' => 'Bad ISBN in 020a field.',
				'params' => {
					'Value' => $isbn,
				},
			);
		} elsif (! $isbn_obj->is_valid) {
			$isbn_obj->fix_checksum;
			if (! $isbn_obj->is_valid) {
				push @record_errors, Data::MARC::Validator::Report::Error->new(
					'error' => 'Bad ISBN in 020a field after fixing of checksum.',
					'params' => {
						'Value' => $isbn,
					},
				);
			} else {
				push @record_errors, Data::MARC::Validator::Report::Error->new(
					'error' => 'Bad checksum of ISBN in 020a field.',
					'params' => {
						'Value' => $isbn,
					},
				);
			}
		} else {
			if ($isbn_obj->as_string ne $isbn) {
				if ((length $isbn_obj->as_string) != (length $isbn)) {
					push @record_errors, Data::MARC::Validator::Report::Error->new(
						'error' => 'Bad ISBN in 020a field, extra characters.',
						'params' => {
							'Value' => $isbn,
						},
					);
				} else {
					push @record_errors, Data::MARC::Validator::Report::Error->new(
						'error' => 'Bad ISBN in 020a field, bad formatting.',
						'params' => {
							'Value' => $isbn,
						},
					);
				}
			}
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
