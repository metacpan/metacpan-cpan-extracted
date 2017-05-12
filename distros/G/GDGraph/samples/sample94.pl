use GD::Graph::pie;
use strict;
require 'save.pl';

# Test for very large slices that wrap around, and for text that
# is larger than the pie boundaries

print STDERR "Processing sample94\n";

my @data = ( 
    ["Oversized label", "label", undef],
    [3, 2.5, 23]
);

my $my_graph = new GD::Graph::pie( 250, 200 );

$my_graph->set( 
	title => 'A Pie Chart',
	label => 'Label',
	axislabelclr => 'black',
	pie_height => 36,
	l_margin => 10,
	r_margin => 10,
	# approximate boundary conditions for start_angle
	#start_angle => -85,
	#start_angle => 15,

	transparent => 0,
);

$my_graph->set_value_font(GD::Font->Giant);

$my_graph->plot(\@data);
save_chart($my_graph, 'sample94');


1;
