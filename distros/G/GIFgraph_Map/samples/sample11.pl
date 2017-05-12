use GIFgraph::bars;
use GIFgraph::colour;
use GIFgraph::Map;

print STDERR "Processing sample 1-1\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
);

@hrefs = ['http://www.perl.com', 'http://www.freshmeat.net', 'http://www.debian.org', 'javascript:alert(\'Sample of using JavaScript in hrefs.\')'];

$my_graph = new GIFgraph::bars(600, 400);

$my_graph->set( 
	'x_label' => 'X Label',
	'y_label' => 'Y label',
	'title' => 'A Simple Bar Chart',
	'y_max_value' => 8,
	'y_tick_number' => 8,
	'y_label_skip' => 2,
	'bar_spacing' => 3
);

$my_graph->plot_to_gif( "sample11.gif", \@data );

open(OUT, ">sample11.html");

$map = new GIFgraph::Map($my_graph, newWindow => 1);

$map->set(hrefs => \@hrefs);

print OUT "<html>\n<body>\n";

print OUT $map->imagemap("sample11.gif", \@data);

print OUT "</body>\n</html>";

close OUT;
 
exit;

