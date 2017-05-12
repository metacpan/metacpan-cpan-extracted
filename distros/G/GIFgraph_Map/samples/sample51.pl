use GIFgraph::pie;
use GIFgraph::Map;

print STDERR "Processing sample 5-1\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th"],
    [ 2.24, 4.34, 5.23, 1.94, 5.03, 2.35]
);

$my_graph = new GIFgraph::pie( 600, 400 );

$my_graph->set( 
	'title' => 'A Pie Chart',
	'label' => 'Label',
	'axislabelclr' => 'black',
	'pie_height' => 80,
);

$my_graph->plot_to_gif( "sample51.gif", \@data );

open(OUT, ">sample51.html");

$map = new GIFgraph::Map($my_graph);

$map->set(info => '%x field contains %p% of %.1s');

print OUT "<html>\n<body>\n";

print OUT $map->imagemap("sample51.gif", \@data);

print OUT "</body>\n</html>";

close OUT;
 
exit;

