use GD::Graph::lines;
use GD::Graph::Map;

print STDERR "Processing sample 5-2\n";

@data = ( 
    [ qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) ],
    [ reverse(4, 3, 5, 6, 3,  1.5, -1, -3, -4, -6, -7, -8)],
    [        (4, 3, 5, 6, 3,  1.5, -1, -3, -4, -6, -7, -8)],
    [        (2, 2, 2, 5, 5,  4.5,1.5,  2,  3,  5,  4,  3)],
);

$my_graph = new GD::Graph::lines();

$my_graph->set( 
	x_label => 'Month',
	y_label => 'Measure of success',
	title => 'A Multiple Line Graph',

	y_max_value => 8,
	y_min_value => -8,
	y_tick_number => 16,
	y_label_skip => 2,
	box_axis => 0,
	line_width => 3,
	zero_axis_only => 1,
	x_label_position => 1,
	y_label_position => 1,

	x_label_skip => 3,
	x_tick_offset => 2,
);

$my_graph->set_legend("Us", "Them", "Others");

open PNG, ">sample52.png";
binmode PNG; #only for Windows like platforms
print PNG $my_graph->plot(\@data)->png;
close PNG;

$map = new GD::Graph::Map($my_graph, info => '%l');

open HTML, ">sample52.html";
print HTML "<HTML><BODY BGCOLOR=white>\n".
  ($map->imagemap("sample52.png", \@data)).
  "</BODY></HTML>";
close HTML;

__END__
