use strict;
use GD::Graph::lines;
require 'save.pl';
use constant PI => 4 * atan2(1,1);

print STDERR "Processing sample55\n";

my @x = map {$_ * 3 * PI/100} (0 .. 100);
my @y = map sin, @x;
my @z = map cos, @x;

my @data = (\@x,\@y,\@z);

my $my_graph = new GD::Graph::lines();

$my_graph->set(
	x_label 			=> 'Angle (Radians)',
	y_label 			=> 'Trig Function Value',
	x_tick_number 		=> 'auto',
	y_tick_number 		=> 'auto',
	title 				=> 'Sine and Cosine',
	line_width 			=> 1,
	x_label_position 	=> 1/2,
	r_margin 			=> 15,

	transparent 		=> 0,
);

$my_graph->set_legend('Thanks to Scott Prahl');

$my_graph->plot(\@data);
save_chart($my_graph, 'sample55');


1;
