use GD::Graph::boxplot;



# sample01.png

$one = [27, -35, 14, 29, 39, 52];
$two = [41, -140, 29, 45, 62, 125];
$three = [100, 30, 88, 95, 115, 155];
$four = [80, -100, 60, 100, 110, 195];

@data = ( 
	["1st", "2nd", "3rd", "4th"],
	[ $one, $two, $three, $four],
	);
	
$my_graph = new GD::Graph::boxplot();

$my_graph->set(
	box_spacing		=> 35,
	do_stats		=> 0
	);

# Output the graph 

$gd = $my_graph->plot(\@data);

open(IMG, '>sample01.png') or die $!;
binmode IMG;
print IMG $gd->png;




# sample02.png

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
	
$my_graph = new GD::Graph::boxplot();

$my_graph->set(
	x_label        => 'Day',
	y_label        => 'Units',
	title          => 'Title',
	y_max_value    => 140,
	y_min_value    => -80,
	y_tick_number  => 11
	);

# Output the graph 

$gd = $my_graph->plot(\@data);

open(IMG, '>sample02.png') or die $!;
binmode IMG;
print IMG $gd->png;



# sample03.png

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
	
$my_graph = new GD::Graph::boxplot(640, 480);

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

$gd = $my_graph->plot(\@data);

open(IMG, '>sample03.png') or die $!;
binmode IMG;
print IMG $gd->png;



# sample04.png

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
	
$my_graph = new GD::Graph::boxplot();

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

$gd = $my_graph->plot(\@data);

open(IMG, '>sample04.png') or die $!;
binmode IMG;
print IMG $gd->png;



# sample05.png

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
	
$my_graph = new GD::Graph::boxplot();

$my_graph->set(
	y_max_value       => 250,
	y_min_value       => -220,
	dclrs             => [ qw(lblue lgreen cyan lyellow) ],
	box_spacing       => 5 
	);

# Output the graph 

$gd = $my_graph->plot(\@data);

open(IMG, '>sample05.png') or die $!;
binmode IMG;
print IMG $gd->png;