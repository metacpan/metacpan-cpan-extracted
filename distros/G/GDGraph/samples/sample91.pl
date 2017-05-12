use GD::Graph::pie;
require 'save.pl';

print STDERR "Processing sample91\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th"],
    [    4,    2,    3,    4,    3,  3.5]
);

$my_graph = new GD::Graph::pie( 250, 200 );
#$my_graph = new GD::Graph::pie( );

$my_graph->set( 
	title => 'A Pie Chart',
	label => 'Label',
	axislabelclr => 'black',
	pie_height => 36,

	l_margin => 15,
	r_margin => 15,

	start_angle => 235,

	transparent => 0,
);

$my_graph->plot(\@data);
save_chart($my_graph, 'sample91');


1;
