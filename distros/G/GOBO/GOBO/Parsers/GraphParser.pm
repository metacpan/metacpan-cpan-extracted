package GOBO::Parsers::GraphParser;
use Moose::Role;
use GOBO::Graph;

has graph => (is=>'rw', isa=>'GOBO::Graph', default=>sub{new GOBO::Graph}, clearer=>'_clear_graph');

=head2 clear_graph

get rid of any existing data

=cut
	
sub clear_graph {
	my $self = shift;
	$self->_clear_graph;
	
	my $g = new GOBO::Graph;
	$self->graph( $g );
	return;
}

## alter the reset_parser function so that the graph data is also removed

after 'reset_parser' => sub {
	my $self = shift;
	$self->clear_graph;
};

1;
