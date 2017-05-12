use GIFgraph::linespoints;
use GIFgraph::Map;

print STDERR "Processing sample 4-1\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,    5,    6,    3,  1.5,    undef,     3,     4],
    [    5,   12,   24,   33,   undef,    8,    6,    15,    21],
);

$my_graph = new GIFgraph::linespoints(600, 400);

$my_graph->set( 
	'x_label' => 'X Label',
	'y_label' => 'Y label',
	'title' => 'A Lines and Points Graph',
	'y_max_value' => 40,
	'y_tick_number' => 8,
	'y_label_skip' => 2,
	'markers' => [ 1, 5 ],
);

$my_graph->set_legend( 'data set 1', 'data set 2' );

$my_graph->plot_to_gif( "sample41.gif", \@data );


open(OUT, ">sample41.html");

$map = new GIFgraph::Map($my_graph);

$map->set(info =>'%l:  x=%x  y=%y');

print OUT "<html>\n<body>\n";

print OUT $map->imagemap("sample41.gif", \@data);

print OUT "</body>\n</html>";

close OUT;

exit;

