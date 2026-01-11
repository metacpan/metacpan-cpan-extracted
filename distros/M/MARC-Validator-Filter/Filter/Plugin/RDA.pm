package MARC::Validator::Filter::Plugin::RDA;

use base qw(MARC::Validator::Filter::Abstract);
use strict;
use warnings;

our $VERSION = 0.01;

sub name {
	my $self = shift;

	return 'rda';
}

sub process {
	my ($self, $marc_record) = @_;

	my $field_040 = $marc_record->field('040');
	if (! defined $field_040) {
		return;
	}

	my $desc_conventions = $field_040->subfield('e');
	if (! defined $desc_conventions) {
		return;
	}

	if ($desc_conventions ne 'rda') {
		return;
	}

	return 'rda';
}

1;

__END__
