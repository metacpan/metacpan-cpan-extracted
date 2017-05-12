use strict;
use GD::Graph::mixed;
require 'save.pl';

# Also see sample17

print STDERR "Processing sample63\n";

my @data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [   11,   12,   15,   16,    3,  1.5,    1,     3,     4],
    [    5,   12,   24,   15,   19,    8,    6,    15,    21],
    [   12,    3,    1,   5,    12,    9,   16,    25,    11],
	[   16,   24,   39,   31,   22,   9.5,   7,    18,    25],
);

my $my_graph = new GD::Graph::mixed();

$my_graph->set( 
	x_label 		=> 'X Label',
	y_label 		=> 'Y label',
	title 			=> 'Emulation of error bars',
	y_min_value 	=> 0,
	y_max_value 	=> 50,
	y_tick_number 	=> 10,
	y_label_skip 	=> 2,
	cumulate 		=> 1,
	types 			=> [qw(area bars bars lines)],
	dclrs 			=> [undef, qw(lgray gray red)],
	borderclrs 		=> [undef, qw(black black black)],
	line_width 		=> 2,
	bar_width		=> 4,

	transparent 	=> 0,
)
or warn $my_graph->error;

$my_graph->set_legend(undef, qw(increment more));
$my_graph->plot(\@data) or die $my_graph->error;
save_chart($my_graph, 'sample63');


1;
