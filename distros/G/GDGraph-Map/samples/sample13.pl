use GD::Graph::bars;
use GD::Graph::Map;

print STDERR "Processing sample 1-3\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    5,   12,   24,   33,   19,    8,    6,    15,    21],
    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4]
);

$my_graph = new GD::Graph::bars();

$my_graph->set( 
	x_label => 'X Label',
	y_label => 'Y label',
	title => 'Bars in front of each other',
	y_tick_number => 8,
	y_label_skip => 2,
	overwrite => 1,
	bar_spacing => 8,
	shadow_depth => 4,
);

$my_graph->set_legend('Data set 1', 'Data set 2');

open PNG, ">sample13.png";
binmode PNG; #only for Windows like platforms
print PNG ($my_graph->plot(\@data))->png;
close PNG;

$map = new GD::Graph::Map($my_graph, info => '%l:  x=%x   y=%y');

open HTML, ">sample13.html";
print HTML "<HTML><BODY BGCOLOR=white>\n".
  ($map->imagemap("sample13.png", \@data)).
  "</BODY></HTML>";
close HTML;

__END__
