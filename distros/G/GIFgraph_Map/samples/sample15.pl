use GIFgraph::bars;
use GIFgraph::Map;

print STDERR "Processing sample 1-5\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,   35,   16,    3,  1.5,    1,     3,     4],
    [    5,   12,   24,   15,   19,    8,    6,    15,    21],
);

$my_graph = new GIFgraph::bars(600, 400);

$my_graph->set( 
	'x_label' => 'X Label',
	'y_label' => 'Y label',
	'title' => 'Bars on top of each other (incremental)',
	'y_tick_number' => 8,
	'y_label_skip' => 2,
	'overwrite' => 2,
);

$my_graph->set_legend( 'offset', 'increment');

$my_graph->plot_to_gif( "sample15.gif", \@data );

open(OUT, ">sample15.html");

$map = new GIFgraph::Map($my_graph);

print OUT "<html>\n<body>\n";

print OUT $map->imagemap("sample15.gif", \@data);

print OUT "</body>\n</html>";

close OUT;

exit;

