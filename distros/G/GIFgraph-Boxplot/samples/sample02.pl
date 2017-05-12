use GIFgraph::boxplot;

$sun = [1, 3, 4, 5, 6, 7, 11, 23, 34, 56, 78, 79, 80, 81, 110];
$mon = [5, 19, 21, 23, 24, 38];
$tue = [7, 27, 38, 49, 52, 53, 55, 57, 59, 61, 63, 90, 125];
$wed = [20..30, 60..80, 100, 135];
$thur = [1, 10, 40, 70, 75, 80, 100, 120];
$fri = [-75, 90, -54, -29, 84, 78, 110];
$sat = [ int(rand 210)-75, int(rand 210)-75, int(rand 210)-75, int(rand 210)-75 ];

@data = ( 
	["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
	[ [0..20], [10..30], [20..40], [30..50], [40..60], [50..70], [60..80] ],
	[ $sun, $mon, $tue, $wed, $thu, $fri, $sat ]
	);
	
$my_graph = new GIFgraph::boxplot();

$my_graph->set(
	x_label        => 'Day',
	y_label        => 'Units',
	title          => 'Title',
	y_max_value    => 140,
	y_min_value    => -80,
	y_tick_number  => 11
	);

# Output the graph 
$my_graph->plot_to_gif( "sample02.gif", \@data );


