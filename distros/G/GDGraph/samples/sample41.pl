use GD::Graph::linespoints;
require 'save.pl';

print STDERR "Processing sample41\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [undef,  52,  53,  54,  55,  56,  undef,  58,  59],
    [60,  61,  61,  undef,  68,  66,  65,  61, undef],
    [70,  undef,  71,  undef,  78,  undef,  75,  71, undef],
);

$my_graph = new GD::Graph::linespoints( );

$my_graph->set( 
	x_label => 'X Label',
	y_label => 'Y label',
	title => 'A Lines and Points Graph',
	y_max_value => 80,
	y_tick_number => 6,
	y_label_skip => 2,
	y_long_ticks => 1,
	x_tick_length => 2,
	markers => [ 1, 5 ],

	skip_undef => 1,

	transparent => 0,

) or warn $my_graph->error;

$my_graph->set_legend( 'data set 1', 'data set 2', 'data set 3' );
$my_graph->plot(\@data);
save_chart($my_graph, 'sample41');


1;
