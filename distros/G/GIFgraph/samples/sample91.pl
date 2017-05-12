use GIFgraph::pie;
use strict;

print STDERR "Processing sample 9-1\n";

my @data = ( 
    ["1st","2nd","3rd","4th","5th","6th"],
    [    4,    2,    3,    4,    3,  3.5]
);

my $my_graph = new GIFgraph::pie( 250, 200 );

$my_graph->set( 
	title => 'A Pie Chart',
	label => 'Label',
	axislabelclr => 'black',
	pie_height => 36,
);

my $gif_data = $my_graph->plot(\@data);
open(GIF, '>sample91.gif') or die "Cannot write sample91.gif: $!";
binmode(GIF);
print GIF $gif_data;
close(GIF);

