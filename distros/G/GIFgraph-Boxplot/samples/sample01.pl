use GIFgraph::boxplot;

$one = [27, -35, 14, 29, 39, 52];
$two = [41, -140, 29, 45, 62, 125];
$three = [100, 30, 88, 95, 115, 155];
$four = [80, -100, 60, 100, 110, 195];

@data = ( 
	["1st", "2nd", "3rd", "4th"],
	[ $one, $two, $three, $four],
	);
	
$my_graph = new GIFgraph::boxplot();

$my_graph->set(
	box_spacing		=> 35,
	do_stats		=> 0
	);

# Output the graph 
$my_graph->plot_to_gif( "sample01.gif", \@data );


