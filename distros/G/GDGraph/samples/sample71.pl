use strict;
use GD::Graph::mixed;
require 'save.pl';

print STDERR "Processing sample71\n";

my @data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,    5,    6,    3,  1.5,   -1,    -3,    -4],
    [   -4,   -3,    1,    1,   -3, -1.5,   -2,    -1,     0],
    [    9,    8,    9,  8.4,  7.1,  7.5,    8,     3,    -3],
    [  0.1,  0.2,  0.5,  0.4,  0.3,  0.5,  0.1,     0,   0.4],
    [ -0.1,    2,    5,    4,   -3,  2.5,  3.2,     4,    -4],
);
my ($width, $height) = (500, 400);
my $my_graph = new GD::Graph::mixed($width, $height);

$my_graph->set( 
	types => [ qw( lines bars points area linespoints ) ],
	default_type => 'points',
);

$my_graph->set( 

	x_label => 'X Label',
	y_label => 'Y label',
	title => 'Mixed Type and TTF',

	y_max_value => 10,
	y_min_value => -5,
	y_tick_number => 3,
	y_label_skip => 1,
	x_plot_values => 1,
	y_plot_values => 1,

	long_ticks => 1,
	x_ticks => 0,
	x_labels_vertical => 1,

	legend_marker_width => 24,
	line_width => 3,
	marker_size => 5,

	bar_spacing => 6,

	legend_placement => 'RC',

	transparent => 0,
);

$my_graph->set_title_font('../Dustismo_Sans.ttf', 18);
$my_graph->set_x_label_font('../Dustismo_Sans.ttf', 10);
$my_graph->set_y_label_font('../Dustismo_Sans.ttf', 10);
$my_graph->set_x_axis_font('../Dustismo_Sans.ttf', 8);
$my_graph->set_y_axis_font('../Dustismo_Sans.ttf', 8);
$my_graph->set_legend_font('../Dustismo_Sans.ttf', 9);

$my_graph->set_legend( qw( one two three four five six ) );

# Put some background text in, but only if we have TTF support

if ($my_graph->can_do_ttf)
{
    my $gd = $my_graph->gd;
    my $white = $gd->colorAllocate(255,255,255);
    my $pink = $gd->colorAllocate(255,240,240);
    my $gdta;

    $gdta = GD::Text::Align->new($gd,
	text => 'GD::Graph',
	font => '../Dustismo_Sans.ttf',
	ptsize => 72,
	colour => $pink,
	valign => 'center',
	halign => 'center',
    ) or warn $gdta->error;

    $gdta->draw($width/2, $height/2, atan2($height, $width));
}

$my_graph->plot(\@data);

# Use a hotspot to draw some extra text on the chart
# XXX This doesn't work nicely. Need a nicer way to get the maximum.
if (1) {
    my $gd = $my_graph->gd;
    my $red = $gd->colorResolve(255,0,0);
    my @l = $my_graph->get_hotspot(1, 3);
    my ($x, $y) = ( ($l[1] + $l[3])/2, ($l[2] + $l[4])/2 );
    my $gdta;

    $gdta = GD::Text::Align->new($gd,
	text => 'maximum',
	font => ['../Dustismo_Sans.ttf', GD::Font->Small],
	ptsize => 12,
	colour => $red,
	valign => 'bottom',
	halign => 'center',
    ) or warn $gdta->error;
    
    $gdta->draw($x, $y + 2);
}


save_chart($my_graph, 'sample71');


1;
