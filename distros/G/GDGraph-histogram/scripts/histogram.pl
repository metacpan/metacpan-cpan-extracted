use strict;
use GD::Graph::histogram;

my @data;
for (my $i = 0; $i < 100; $i++)
{
	push(@data, rand(50));
}

my $graph = new GD::Graph::histogram(450,450);

$graph->set( 
                x_label         => 'Jelly Beans',
                y_label         => 'Count',
                title           => 'A Simple Count Histogram Chart',
                x_labels_vertical => 1,
                bar_spacing     => 0,
                shadow_depth    => 1,
                shadowclr       => 'dred',
                transparent     => 0,
        ) 
        or warn $graph->error;

my $gd = $graph->plot(\@data) or die $graph->error;

open(IMG, '>file.png') or die $!;
binmode IMG;
print IMG $gd->png;
