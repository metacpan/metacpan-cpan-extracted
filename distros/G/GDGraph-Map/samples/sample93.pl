use GD::Graph::pie;
use GD::Graph::Map;

print STDERR "Processing sample 9-3\n";

@data = ( 
	[ qw( 1st 2nd 3rd 4th 5th 6th 7th ) ],
	[ sort { $b <=> $a} (5.6, 2.1, 3.03, 4.05, 1.34, 0.2, 2.56) ]
);

$my_graph = new GD::Graph::pie( 200, 200 );

$my_graph->set( 
	start_angle => 90,
	'3d' => 0,
	label => 'Foo Bar',
	# The following should prevent the 7th slice from getting a label
	suppress_angle => 5, 
);

open PNG, ">sample93.png";
binmode PNG; #only for Windows like platforms
print PNG $my_graph->plot(\@data)->png;
close PNG;

$map = new GD::Graph::Map($my_graph, info => '%x:  %y (%p%)');

open HTML, ">sample93.html";
print HTML "<HTML><BODY BGCOLOR=white>\n".
  ($map->imagemap("sample93.png", \@data)).
  "</BODY></HTML>";
close HTML;

