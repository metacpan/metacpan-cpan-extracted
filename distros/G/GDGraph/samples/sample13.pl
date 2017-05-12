use strict;
use GD::Graph::bars;
use GD::Graph::hbars;
require 'save.pl';

my @data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    5,   12,   24,   33,   19,    8,    6,    15,    21],
    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4]
);

my @names = qw/sample13 sample13-h/;

for my $my_graph (GD::Graph::bars->new, GD::Graph::hbars->new)
{
    my $name = shift @names;
    print STDERR "Processing $name\n";

    $my_graph->set( 
	x_label         => 'X Label',
	y_label         => 'Y label',
	title           => 'Bars in front of each other',
	#y_tick_number   => 8,
	#y_label_skip    => 2,
	overwrite       => 1,
	bar_spacing     => 8,
	shadow_depth    => 4,

	transparent     => 0,
    );

    $my_graph->plot(\@data);
    save_chart($my_graph, $name);
}

1;
