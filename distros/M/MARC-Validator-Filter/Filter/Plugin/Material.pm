package MARC::Validator::Filter::Plugin::Material;

use base qw(MARC::Validator::Filter::Abstract);
use strict;
use warnings;

use English;
use MARC::Leader 0.08;
use MARC::Leader::Utils 0.02 qw(material_type);

our $VERSION = 0.01;

sub name {
	my $self = shift;

	return 'material';
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
	my $material_type = material_type($leader);

	return 'material_'.$material_type;
}

1;

__END__
