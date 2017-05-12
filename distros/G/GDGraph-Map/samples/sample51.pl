use GD::Graph::lines;
use GD::Graph::Map;

print STDERR "Processing sample 5-1\n";

@data = ( 
    [ qw( Jan Feb Mar Apr May Jun Jul Aug Sep ) ],
    [ reverse(4, 3, 5, 6, 3,  1.5, -1, -3, -4)],
);

$my_graph = new GD::Graph::lines();

$my_graph->set( 
	x_label => 'Month',
	y_label => 'Measure of success',
	title => 'A Simple Line Graph',
	y_max_value => 8,
	y_min_value => -6,
	y_tick_number => 14,
	y_label_skip => 2,
	box_axis => 0,
	line_width => 3,
);

open PNG, ">sample51.png";
binmode PNG; #only for Windows like platforms
print PNG $my_graph->plot(\@data)->png;
close PNG;

$map = new GD::Graph::Map($my_graph, info => '%l');

open HTML, ">sample51.html";
print HTML "<HTML><BODY BGCOLOR=white>\n".
  ($map->imagemap("sample51.png", \@data)).
  "</BODY></HTML>";
close HTML;

__END__