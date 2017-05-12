use GD::Graph::area;
use strict;
require 'save.pl';

my @data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    5,   12,   24,   33,   19,undef,    6,    15,    21],
    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4]
);

my @names = qw/sample21/;

for my $graph (GD::Graph::area->new)
{
    my $name = shift @names;
    print STDERR "Processing $name\n";

    $graph->set( 
	x_label => 'X Label',
	y_label => 'Y label',
	title => 'An Area Graph',
	#y_max_value => 40,
	#y_tick_number => 8,
	#y_label_skip => 2,
	#accent_treshold => 41,
	transparent => 0,
    );

    $graph->set_legend( 'one', 'two' );
    $graph->plot(\@data);
    save_chart($graph, $name);
}


1;
