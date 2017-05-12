use GD::Graph::bars;
use GD::Graph::colour;
use GD::Graph::Map;

print STDERR "Processing sample 1-1\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
);

@hrefs = ["http://www.perl.org", 
          "http://www.cpan.org", 
	  "http://freshmeat.net", 
	  "javascript:alert('Sample of using JavaScript');"
];

$my_graph = new GD::Graph::bars();

$my_graph->set( 
	x_label => 'X Label',
	y_label => 'Y label',
	title => 'A Simple Bar Chart',
	y_max_value => 8,
	y_tick_number => 8,
	y_label_skip => 2,
	
	# shadows
	bar_spacing => 8,
	shadow_depth => 4,
	shadowclr => 'dred',
) 
or warn $my_graph->error;

open PNG, ">sample11.png";
binmode PNG; #only for Windows like platforms
print PNG $my_graph->plot(\@data)->png;
close PNG;

$map = new GD::Graph::Map($my_graph, hrefs => \@hrefs);

open HTML, ">sample11.html";
print HTML "<HTML><BODY BGCOLOR=white>\n".
  ($map->imagemap("sample11.png", \@data)).
  "</BODY></HTML>";
close HTML;

__END__
