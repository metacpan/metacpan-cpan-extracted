use GD::Graph::pie;
require 'save.pl';

print STDERR "Processing sample92\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th"],
    [    4,    2,    3,    4,    3,  3.5]
);

$my_graph = new GD::Graph::pie( 250, 200 );

$my_graph->set( 
    title 		=> 'A Pie Chart',
    label 		=> 'Label',
    axislabelclr 	=> 'white',
    dclrs 		=> [ 'lblue' ],
    accentclr 		=> 'lgray',

    transparent 	=> 0,
);

$my_graph->set_title_font('../cetus.ttf', 18);
$my_graph->set_label_font('../cetus.ttf', 12);
$my_graph->set_value_font('../cetus.ttf', 10);

$my_graph->plot(\@data);
save_chart($my_graph, 'sample92');


1;
