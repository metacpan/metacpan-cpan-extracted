use GD::Graph::pie;
require 'save.pl';

print STDERR "Processing sample93\n";

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

	transparent => 0,
);

$my_graph->plot(\@data);
save_chart($my_graph, 'sample93');


1;
