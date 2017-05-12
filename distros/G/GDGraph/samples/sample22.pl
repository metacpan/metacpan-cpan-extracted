use GD::Graph::area;
require 'save.pl';

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    5,   12,   24,   33,   19,    8,    6,    15,    21],
    [   -1,   -2,   -5,   -6,   -3,  1.5,    1,   1.3,     2]
);

my $name = 'sample22';

my $graph = GD::Graph::area->new;

print STDERR "Processing $name\n";

$graph->set( 
	two_axes => 1,
	zero_axis => 1,

	transparent => 0,
);

$graph->set(rotate_chart => 1) if $name =~ /-h$/;

$graph->set_legend( 'left axis', 'right axis' );
$graph->plot(\@data);
save_chart($graph, $name);

1;
