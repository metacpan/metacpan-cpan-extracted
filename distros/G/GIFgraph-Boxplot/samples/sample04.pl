use GIFgraph::boxplot;

$one = [-10..20, 40..50, 190, 210];
$two = [130..180, -40, -10];
$three = [80..100, 130..140, 180];
$four = [210..240];
$five = [1, 10, 43, 89, -100, 90, 102];

$labels = [ "one", "two", "three", "four", "five" ];

@data = ( 
	$labels, 
	[ $one, $two, $three, $four, $five ],
	[ [1..30], [11..50], [21..80], [31..100], [41..150] ],
	[ [1..50], [40..70], [50..90], [70..120], [90..120] ],
	[ [-200..200], [-100..100], [-50..50], [-25..25], [undef] ]
	);
	
$my_graph = new GIFgraph::boxplot();

$my_graph->set(
	x_label           => 'X',
	y_label           => 'Y',
	upper_percent     => 80,
	lower_percent     => 20,
	step_const        => 1,
	fov_const         => 1.5,
	y_max_value       => 250,
	y_min_value       => -220,
	box_spacing       => 5,
	r_margin          => 0,
	x_label_position  => 1/4
	);

# Output the graph 
$my_graph->plot_to_gif( "sample04.gif", \@data );


