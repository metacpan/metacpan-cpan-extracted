use strict;
use GD::Graph::mixed;
require 'save.pl';

print STDERR "Processing sample72\n";

my @data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,    5,    6,    3,  1.5,   -1,    -3,    -4],
);
my $my_graph = new GD::Graph::bars();

$my_graph->set( 

    title => 'This is a chart with ridicuklously long labels all ' .
	     'over the place, just to see what that does',
    x_label => 'This is a very long X Label that should span '.
	       'across the whole axis and further',
    y_label => 'This is a very long Y Label that should span '.
	       'across the whole axis and further',
    transparent => 0,

);

$my_graph->set_title_font('../Dustismo_Sans.ttf', 18);
$my_graph->set_x_label_font('../Dustismo_Sans.ttf', 10);
$my_graph->set_y_label_font('../Dustismo_Sans.ttf', 10);
$my_graph->set_x_axis_font('../Dustismo_Sans.ttf', 8);
$my_graph->set_y_axis_font('../Dustismo_Sans.ttf', 8);
$my_graph->set_legend_font('../Dustismo_Sans.ttf', 9);

$my_graph->plot(\@data);

save_chart($my_graph, 'sample72');


1;
