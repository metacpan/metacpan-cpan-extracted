use lib '.';
use GD::Graph::xylines;
use GD::Graph::xypoints;
use GD::Graph::xylinespoints;

my $gd;

@data = ( 
	[7, -6, 4, 3,4,5,6,7,7,7,7],
	[ -1, 2, 3, 4,4,5,6,7,-1,-2,-6]
	);
	
$my_graph = new GD::Graph::xylines(600,400);

$my_graph->set(
	title		=> 'I am the Walrus',
	x_label	=> 'Monkey',
	y_label	=> 'Donkey'
);

$gd = $my_graph->plot(\@data);

open(IMG, '>xylines.png') or die $!;
binmode IMG;
print IMG $gd->png;


@data = ( 
	[7, -6, 4, 3,4,5,6,7,7,7,7],
	[ -1, 2, 3, 4,4,5,6,7,-1,-2,-6]
);
	
$my_graph = new GD::Graph::xypoints(600,400);

$my_graph->set(
	title		=> 'I am the Walrus',
	x_label	=> 'Monkey',
	y_label	=> 'Donkey',
	x_number_format	=> "\$%.2f"
);

  $gd = $my_graph->plot(\@data);

open(IMG, '>xypoints.png') or die $!;
binmode IMG;
print IMG $gd->png;


$my_graph = new GD::Graph::xylinespoints(600,400);

sub x_format
{
    my $value = shift;
    my $ret;

    if ($value >= 0)
    {
        $ret = "Up '$value'";
    }
    else
    {
        $ret = "Down '$value'";
    }

    return $ret;
}

$my_graph->set(
	title		=> 'I am the Walrus',
	x_label	=> 'Monkey',
	y_label	=> 'Donkey',
	x_number_format	=> \&x_format
  );

$gd = $my_graph->plot(\@data);

open(IMG, '>xylinespoints.png') or die $!;
binmode IMG;
print IMG $gd->png;