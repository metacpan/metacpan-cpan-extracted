# This module does nothing. I use it for testing roles.
package Input;
use Moose;


sub run {
	my ($self, $etl) = @_;

	while (my $path = $self->next_path( $etl )) {
		my $record = {
			base => $path->basename,
			path => $path->relative( $etl->data_in ),
			sub  => {a => 1, b => 2, c => 3, d => 4},
		};
		$etl->record( $record );
	}
}
with 'ETL::Pipeline::Input';
with 'ETL::Pipeline::Input::File::List';


no Moose;
__PACKAGE__->meta->make_immutable;
