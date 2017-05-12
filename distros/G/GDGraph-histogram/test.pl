use strict;
use GD::Graph::histogram;

my $data = [1,5,7,8,9,10,11,3,3,5,5,5,7,2,2];

my $graph = new GD::Graph::histogram(400,600);

$graph->set( 
                x_label         => 'X Label',
                y_label         => 'Count',
                title           => 'A Simple Count Histogram Chart',
                x_labels_vertical => 1,
                bar_spacing     => 0,
                shadow_depth    => 1,
                shadowclr       => 'dred',
                transparent     => 0,
        ) 
        or warn $graph->error;

my $gd = $graph->plot($data) or die $graph->error;

open(IMG, '>file.png') or die $!;
binmode IMG;
print IMG $gd->png;
