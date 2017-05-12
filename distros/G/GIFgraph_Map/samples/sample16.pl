use GIFgraph::bars;
use GIFgraph::Map;

print STDERR "Processing sample 1-6\n";

@data = ( 
    [ qw( 1st 2nd 3rd 4th 5th 6th 7th 8th 9th ) ],
    [    5,   12,undef,   33,   19,    8,    5,    15,    21],
    [   -6,   -5,   -9,   -8,  -11, -9.3,undef,    -9,   -12]
);
$my_graph = new GIFgraph::bars(600, 400);

$my_graph->set( 
	'x_label' => 'Day',
	'y_label' => 'AUD',
	'title' => 'Credits and Debits',
	'y_tick_number' => 12,
	'y_label_skip' => 2,
	'overwrite' => 1, 
	'dclrs' => [ qw( green lred ) ],
	'axislabelclr' => 'black',
	'legend_placement' => 'RB',
	'zero_axis_only' => 0,

);

$my_graph->set_legend( 'credits', 'debets' );

$my_graph->plot_to_gif( "sample16.gif", \@data );

open(OUT, ">sample16.html");

$map = new GIFgraph::Map($my_graph);

print OUT "<html>\n<body>\n";

print OUT $map->imagemap("sample16.gif", \@data);

print OUT "</body>\n</html>";

close OUT;

exit;

