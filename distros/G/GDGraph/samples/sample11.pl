use strict;
use GD::Graph::bars;
use GD::Graph::hbars;
use GD::Graph::Data;
require 'save.pl';

my $data = GD::Graph::Data->new([
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
]) or die GD::Graph::Data->error;

my @names = qw/sample11 sample11-h/;

for my $my_graph (GD::Graph::bars->new, GD::Graph::hbars->new)
{
    my $name = shift @names;

    print STDERR "Processing $name\n";

    $my_graph->set( 
	x_label         => 'X Label',
	y_label         => 'Y label',
	title           => 'A Simple Bar Chart',
	#y_max_value     => 8,
	#y_tick_number   => 8,
	#y_label_skip    => 2,

	#x_labels_vertical => 1,
	
	# shadows
	bar_spacing     => 8,
	shadow_depth    => 4,
	shadowclr       => 'dred',

	transparent     => 0,
    ) 
    or warn $my_graph->error;

    $my_graph->plot($data) or die $my_graph->error;
    save_chart($my_graph, $name);
}


1;
