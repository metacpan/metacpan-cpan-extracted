use GIFgraph::pie;
use GIFgraph::Map;

print STDERR "Processing sample 5-2\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th"],
    [    4,    2,    3,    4,    3,  3.5]
);

$my_graph = new GIFgraph::pie( 600, 400 );

$my_graph->set( 
	'title' => 'A Pie Chart',
	'label' => 'Label',
	'axislabelclr' => 'white',
	'dclrs' => [ 'lblue' ],
	'accentclr' => 'lgray',
);

$my_graph->plot_to_gif( "sample52.gif", \@data );

open(OUT, ">sample52.html");

$map = new GIFgraph::Map($my_graph);

$map->set(info => '%x field contains %.2p% of %s');

print OUT "<html>\n<body>\n";

print OUT $map->imagemap("sample52.gif", \@data);

print OUT "</body>\n</html>";

close OUT;
 
exit;

