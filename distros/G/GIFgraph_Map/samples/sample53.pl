use GIFgraph::pie;
use GIFgraph::Map;

print STDERR "Processing sample 5-3\n";

@data = ( 
	[ qw( 1st 2nd 3rd 4th 5th 6th 7th ) ],
	[ sort { $b <=> $a} (5.6, 2.1, 3.03, 4.05, 1.34, 0.2, 2.56) ]
);


$my_graph = new GIFgraph::pie( 600, 400 );

$my_graph->set( 
	'start_angle' => 90,
	'3d' => 0
);

$my_graph->plot_to_gif( "sample53.gif", \@data );

open(OUT, ">sample53.html");

$map = new GIFgraph::Map($my_graph);

$map->set(info => '%x field contains %p% of %s');

print OUT "<html>\n<body>\n";

print OUT $map->imagemap("sample53.gif", \@data);

print OUT "</body>\n</html>";

close OUT;

exit;

