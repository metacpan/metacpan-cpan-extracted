use GD::Graph::points;
require 'save.pl';

print STDERR "Processing sample31\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    5,   12,   24,   33,   19,    8,    6,    15,    21],
    [    1,    2,    5,    6,    3,  1.5,    undef,     3,     4],
);

$my_graph = new GD::Graph::points();

$my_graph->set( 
	x_label => 'X Label',
	y_label => 'Y label',
	title => 'A Points Graph',
	y_max_value => 40,
	y_tick_number => 8,
	y_label_skip => 2, 
	legend_placement => 'RC',
	long_ticks => 1,
	marker_size => 6,
	markers => [ 9, 10, 1, 7, 5 ],

	transparent => 0,
);

$my_graph->set_legend( qw( one two ) );
$my_graph->plot(\@data);
save_chart($my_graph, 'sample31');


1;
