use GD::Graph::pie;
use GD::Graph::Map;

print STDERR "Processing sample 9-1\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th"],
    [    4,    2,    3,    4,    3,  3.5]
);

$my_graph = new GD::Graph::pie();

$my_graph->set( 
	title => 'A Pie Chart',
	label => 'Label',
	axislabelclr => 'black',
	pie_height => 70,
);

open PNG, ">sample91.png";
binmode PNG; #only for Windows like platforms
print PNG $my_graph->plot(\@data)->png;
close PNG;

$map = new GD::Graph::Map($my_graph, info => '%x: %y (%p%)');

open HTML, ">sample91.html";
print HTML "<HTML><BODY BGCOLOR=white>\n".
  ($map->imagemap("sample91.png", \@data)).
  "</BODY></HTML>";
close HTML;

__END__
