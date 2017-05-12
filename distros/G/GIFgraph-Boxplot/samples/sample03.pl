use GIFgraph::boxplot;

$labels = ["one", "two", "three", "four", "five"];

# since 'do_stats => 0', data are [mean, lowest, lower-%, median, upper-%, highest]
# where lower-% and upper-% are the bottom and top of the box 

$one = [ 	[-10, -100, -50, -20, 40, 100],
		[20, 0, 10, 15, 25, 35],
		[50, -10, 35, 45, 75, 110],
		[80, 40, 55, 70, 100, 105],
		[110, -40, 55, 90, 120, 140] 
	];

$two = [	[45, -100, 20, 55, 80, 140],
		[55, -40, 30, 50, 70, 90],
		[40, -10, 35, 41, 45, 70],
		[50, -120, -10, 35, 75, 150],
		[60, 35, 50, 65, 70, 80]
	];

$three = [	[0, -25, -18, 3, 20, 32],
		[0, -15, -10, 2, 17, 22],
		[0, -12, -9, -1, 7, 10],
		[0, -45, -28, -4, 25, 42],
		[0, -10, -7, -1, 5, 8]
	];


@data = ( 
	$labels, $one, $two, $three
	);
	
$my_graph = new GIFgraph::boxplot(640, 480);

$my_graph->set(
	x_label        => 'X-Label',
	y_label        => 'Y-Label',
	title          => 'Title',
	do_stats       => 0,
	symbolc        => 'black',
	y_min_value    => -150,
	y_max_value    => 200
	);

# Output the graph 
$my_graph->plot_to_gif( "sample03.gif", \@data );


