# This module does nothing. I use it for testing roles.
package TabularInput;
use Moose;

extends 'ETL::Pipeline::Input::UnitTest';

sub get_column_names {
	my ($self) = @_;
	
	$self->next_record;
	
	my @fields = $self->fields;
	while (my ($index, $value) = each @fields) {
		if ($index % 2) {
			$self->add_column( $value );
		} else {
			$self->add_column( $value, $index );
		}
	}
}

with 'ETL::Pipeline::Input::Tabular';

no Moose;
__PACKAGE__->meta->make_immutable;
