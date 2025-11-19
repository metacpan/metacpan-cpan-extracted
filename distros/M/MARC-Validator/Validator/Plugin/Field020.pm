package MARC::Validator::Plugin::Field020;

use base qw(MARC::Validator::Abstract);
use strict;
use warnings;

use Business::ISBN;
use English;
use Error::Pure::Utils qw(err_get);
use MARC::Validator::Utils qw(add_error);

our $VERSION = 0.07;

sub name {
	my $self = shift;

	return 'field_020';
}

sub process {
	my ($self, $marc_record) = @_;

	my $struct_hr = $self->{'struct'}->{'checks'};

	my $error_id = $self->{'cb_error_id'}->($marc_record);

	my @isbn_fields = $marc_record->field('020');
	foreach my $isbn_field (@isbn_fields) {
		my $isbn = $isbn_field->subfield('a');
		if (! defined $isbn) {
			next;
		}
		my $isbn_obj = Business::ISBN->new($isbn);
		if (! defined $isbn_obj) {
			add_error($error_id, $struct_hr, {
				'error' => 'Bad ISBN in 020a field.',
				'params' => {
					'Value' => $isbn,
				},
			});
		} elsif (! $isbn_obj->is_valid) {
			$isbn_obj->fix_checksum;
			if (! $isbn_obj->is_valid) {
				add_error($error_id, $struct_hr, {
					'error' => 'Bad ISBN in 020a field after fixing of checksum.',
					'params' => {
						'Value' => $isbn,
					},
				});
			} else {
				add_error($error_id, $struct_hr, {
					'error' => 'Bad checksum of ISBN in 020a field.',
					'params' => {
						'Value' => $isbn,
					},
				});
			}
		} else {
			if ($isbn_obj->as_string ne $isbn) {
				if ((length $isbn_obj->as_string) != (length $isbn)) {
					add_error($error_id, $struct_hr, {
						'error' => 'Bad ISBN in 020a field, extra characters.',
						'params' => {
							'Value' => $isbn,
						},
					});
				} else {
					add_error($error_id, $struct_hr, {
						'error' => 'Bad ISBN in 020a field, bad formatting.',
						'params' => {
							'Value' => $isbn,
						},
					});
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
