package MARC::Validator::Filter::Plugin::AACR2;

use base qw(MARC::Validator::Filter::Abstract);
use strict;
use warnings;

use English;
use MARC::Leader 0.08;

our $VERSION = 0.01;

sub name {
	my $self = shift;

	return 'aacr2';
}

sub process {
	my ($self, $marc_record) = @_;

	my $leader_string = $marc_record->leader;
	my $leader = eval {
		MARC::Leader->new(
			'verbose' => $self->{'verbose'},
		)->parse($leader_string);
	};
	if ($EVAL_ERROR) {
		return;
	}
	if ($leader->descriptive_cataloging_form ne 'a') {
		return;
	}

	return 'aacr2';
}

1;

__END__
